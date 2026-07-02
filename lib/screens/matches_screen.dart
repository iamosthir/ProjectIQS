import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/util/asset_url.dart';
import '../core/util/date_fmt.dart';
import '../features/matches/application/matches_providers.dart';
import '../features/matches/data/fixture.dart';
import '../features/notifications/application/notifications_providers.dart';
import '../shared/l10n/l10n_ext.dart';
import '../shared/widgets/app_states.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/clay.dart';
import '../widgets/app_header.dart';
import '../widgets/clay_card.dart';
import '../widgets/clay_icon_button.dart';
import '../widgets/network_image_box.dart';

/// المباريات — fixtures list with a filter bar (الكل / اليوم / غداً / انتهت).
///
/// Translated from `ui/IQS Scores.dc.html`. The green header (with the filter
/// pill bar) lives inside the scroll, so it scrolls away. The bottom nav is
/// provided globally by the shell scaffold and is intentionally absent here.
///
/// Phase 2: the hardcoded `_Match` lists are replaced by the live `/fixtures`
/// feed. The widget tree/styling is unchanged — only the data source. Filters
/// map to the API: الكل → today + tomorrow sections, اليوم/غداً → `date`,
/// انتهت → `status_group=finished`. Cards drill into `/fixtures/:id`.
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  int _filter = 0;

  List<String> _filterLabels(BuildContext context) => [
        context.l10n.matchesNavFilterAll,
        context.l10n.matchesNavFilterToday,
        context.l10n.matchesNavFilterTomorrow,
        context.l10n.matchesNavFilterEnded,
      ];

  // Stable crest colours (the design uses coloured star crests, not logos);
  // derived from team id so each club keeps a consistent colour.
  static const List<Color> _crestPalette = [
    Color(0xFF16357A),
    Color(0xFF1F53B0),
    Color(0xFF2A2A2A),
    Color(0xFF2F8F3E),
    Color(0xFF1B7A3E),
    Color(0xFF2060C0),
    Color(0xFF15306E),
    Color(0xFFE0A416),
  ];

  Color _crestColor(int id) => _crestPalette[id % _crestPalette.length];

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () async {
          ref.invalidate(fixturesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              ..._buildSections(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ header
  Widget _buildHeader() {
    return AppHeader(
      gradient: AppColors.header,
      bottomRadius: 36,
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClayHeaderButton(icon: Icons.menu_rounded, onTap: () {}),
              Text(
                context.l10n.navMatches,
                style: AppText.tajawal(
                  size: 24,
                  weight: AppText.extraBold,
                  color: Colors.white,
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final unread =
                      (ref.watch(unreadCountProvider).valueOrNull ?? 0) > 0;
                  return ClayHeaderButton(
                    icon: Icons.notifications_none_rounded,
                    badge: unread,
                    onTap: () => context.push('/notifications'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterBar(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final labels = _filterLabels(context);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: Clay.card(radius: 20, gradient: AppColors.surface),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildChip(labels[i], i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    final bool active = _filter == index;
    return GestureDetector(
      onTap: () => setState(() => _filter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 22),
        decoration: active
            ? BoxDecoration(
                gradient: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green1D8040.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ],
              )
            : BoxDecoration(
                gradient: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 9,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
        child: Text(
          label,
          style: AppText.tajawal(
            size: 14,
            weight: AppText.bold,
            color: active ? Colors.white : AppColors.chipInactiveText,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- sections
  /// Builds the section list according to the active filter (mirrors the
  /// original structure: الكل → اليوم + غداً sections).
  List<Widget> _buildSections() {
    // The backend filters `date=` with `whereDate` against UTC-stored
    // datetimes, so compute the day key in UTC to match its basis.
    final nowUtc = DateTime.now().toUtc();
    final today = _ymd(nowUtc);
    final tomorrow = _ymd(nowUtc.add(const Duration(days: 1)));
    switch (_filter) {
      case 1:
        return [
          _section(context.l10n.matchesNavFilterToday, FixturesQuery(date: today))
        ];
      case 2:
        return [
          _section(context.l10n.matchesNavFilterTomorrow,
              FixturesQuery(date: tomorrow))
        ];
      case 3:
        return [
          _section(context.l10n.matchesNavFilterEnded,
              const FixturesQuery(statusGroup: 'finished'))
        ];
      case 0:
      default:
        // "All" = the full fixtures feed in one section (the original showed
        // today+tomorrow, but that mapping leaves the tab empty whenever no
        // match is scheduled for those exact dates).
        return [_section(context.l10n.matchesNavAllMatches, const FixturesQuery())];
    }
  }

  Widget _section(String title, FixturesQuery query) {
    final async = ref.watch(fixturesProvider(query));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 4, 4),
          child: Text(
            title,
            style: AppText.tajawal(
              size: 18,
              weight: AppText.extraBold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.start,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: async.when(
            loading: () => const SizedBox(height: 140, child: LoadingState()),
            error: (e, _) => SizedBox(
              height: 160,
              child: appErrorView(
                e,
                onRetry: () => ref.invalidate(fixturesProvider(query)),
              ),
            ),
            data: (page) {
              if (page.items.isEmpty) {
                return SizedBox(
                  height: 130,
                  child: EmptyState(title: context.l10n.matchesNavNoMatches),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < page.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _buildMatchCard(page.items[i]),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- match card
  Widget _buildMatchCard(Fixture f) {
    return ClayCard(
      strong: true,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      onTap: () => context.push('/fixtures/${f.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // RTL: first child (home) renders on the RIGHT.
          Expanded(child: _teamColumn(f.home)),
          Expanded(child: _centerColumn(f)),
          Expanded(child: _teamColumn(f.away)),
        ],
      ),
    );
  }

  Widget _teamColumn(FixtureTeam team) {
    // Real club crest / country flag when the API provides one; the design's
    // coloured star stays as the fallback (same clay circle either way).
    final logo = assetUrl(team.logo);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: Clay.circle(AppColors.crest(_crestColor(team.id))),
          child: logo == null
              ? const Icon(Icons.star_rounded, color: Colors.white, size: 28)
              : NetworkImageBox(url: logo, fit: BoxFit.cover),
        ),
        const SizedBox(height: 11),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.tajawal(
            size: 15,
            weight: AppText.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _centerColumn(Fixture f) {
    final status = f.status;
    final showScore = status.isFinished || status.isLive;
    if (showScore) {
      final score = '${f.home.goals ?? 0} - ${f.away.goals ?? 0}';
      final pill =
          status.isLive ? context.l10n.matchesNavStatusLive : context.l10n.matchesNavStatusEnded;
      final timeText = status.isLive && status.elapsed != null
          ? "${status.elapsed}'"
          : DateFmt.time(f.datetime, locale: 'ar');
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              score,
              style: AppText.tajawal(
                size: 30,
                weight: AppText.black,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 9),
          _statusPill(pill),
          const SizedBox(height: 9),
          Text(
            timeText,
            style: AppText.tajawal(
              size: 13,
              weight: AppText.medium,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.schedule, size: 20, color: AppColors.textMuted),
        const SizedBox(height: 9),
        Text(
          DateFmt.time(f.datetime, locale: 'ar'),
          style: AppText.tajawal(
            size: 19,
            weight: AppText.extraBold,
            color: AppColors.textSubtleGreen,
          ),
        ),
        const SizedBox(height: 9),
        _statusPill(context.l10n.matchesNavStatusNotStarted),
      ],
    );
  }

  Widget _statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: AppText.tajawal(
          size: 13,
          weight: AppText.bold,
          color: AppColors.pillText,
        ),
      ),
    );
  }
}
