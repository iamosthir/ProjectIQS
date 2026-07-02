import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/fixture.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'package:iqs_flutter/widgets/pressable.dart';
import 'comments_feed.dart';
import 'match_detail_tabs.dart';
import 'prediction_section.dart';

const List<Color> _crestPalette = [
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

/// One tab in the match-detail strip.
class _MatchTab {
  const _MatchTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

List<_MatchTab> _tabsFor(AppLocalizations l) => [
      _MatchTab(l.matchDetailTabEvents, Icons.timeline),
      _MatchTab(l.matchDetailTabDetails, Icons.info_outline),
      _MatchTab(l.matchDetailTabLineups, Icons.groups_outlined),
      _MatchTab(l.matchDetailTabStatistics, Icons.bar_chart_rounded),
      _MatchTab(l.matchDetailTabStandings, Icons.format_list_numbered),
      _MatchTab(l.matchDetailTabScores, Icons.scoreboard_outlined),
      _MatchTab(l.matchDetailTabNews, Icons.article_outlined),
      _MatchTab(l.matchDetailTabFanZone, Icons.campaign_outlined),
      _MatchTab(l.matchDetailTabPredictions, Icons.insights_outlined),
    ];

/// Match detail (`/fixtures/:id`). A persistent team/score header with a
/// horizontally-scrollable tab strip below it (Events · Details · Lineups ·
/// Statistics · Standings · Scores · News · Fan Zone · Prediction). Details and
/// Prediction are wired; the rest are placeholders pending data wiring.
class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({super.key, required this.fixtureId});

  final int fixtureId;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  int _tab = 1; // default to التفاصيل (Details)
  FixtureSocial? _socialOverride;
  bool _liking = false;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Polls the live fixture every ~60s while it is in play; stops otherwise.
  void _configurePolling(bool live) {
    if (live) {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 60), (_) {
        ref.invalidate(fixtureDetailProvider(widget.fixtureId));
        // Refresh the live-changing tabs too (events/stats). Lineups are fixed
        // at kickoff and standings update post-match, so they're left alone.
        ref.invalidate(fixtureEventsProvider(widget.fixtureId));
        ref.invalidate(fixtureStatisticsProvider(widget.fixtureId));
      });
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _toggleLike(Fixture f) async {
    if (_liking) return;
    final current = _socialOverride ?? f.social;
    final nowLiked = !current.likedByMe;
    setState(() {
      _liking = true;
      _socialOverride = current.copyWith(
        likedByMe: nowLiked,
        likes: (current.likes + (nowLiked ? 1 : -1)).clamp(0, 1 << 30),
      );
    });
    try {
      final repo = ref.read(matchesRepositoryProvider);
      nowLiked ? await repo.like(f.id) : await repo.unlike(f.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _socialOverride = current); // revert
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(context.l10n.matchDetailLikeUpdateFailed)));
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _share(Fixture f) async {
    final current = _socialOverride ?? f.social;
    setState(() =>
        _socialOverride = current.copyWith(shares: current.shares + 1));
    try {
      await ref.read(matchesRepositoryProvider).share(f.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _socialOverride = current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fixtureDetailProvider(widget.fixtureId));
    final title =
        async.valueOrNull?.league.name ?? context.l10n.matchDetailTitle;

    ref.listen<AsyncValue<Fixture>>(
      fixtureDetailProvider(widget.fixtureId),
      (prev, next) {
        _configurePolling(next.valueOrNull?.status.isLive ?? false);
        if (next.hasValue && !_liking && _socialOverride != null) {
          setState(() => _socialOverride = null);
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                ClayHeaderButton(
                  icon: Icons.ios_share_rounded,
                  iconSize: 20,
                  onTap: () {
                    final f = async.valueOrNull;
                    if (f != null) _share(f);
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.screenTitle,
                    ),
                  ),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/matches'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () =>
                  ref.invalidate(fixtureDetailProvider(widget.fixtureId)),
              data: (f) => _body(f),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(Fixture f) {
    final social = _socialOverride ?? f.social;
    return Column(
      children: [
        // Persistent header: teams + score + social actions.
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            children: [
              _scoreCard(f),
              const SizedBox(height: 12),
              _socialRow(f, social),
            ],
          ),
        ),
        _tabStrip(),
        Expanded(child: _tabContent(f)),
      ],
    );
  }

  // --------------------------------------------------------------- tab strip
  Widget _tabStrip() {
    final tabs = _tabsFor(context.l10n);
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      padding: const EdgeInsets.all(10),
      decoration: Clay.card(radius: 20, gradient: AppColors.sectionTile),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              AppChip(
                label: tabs[i].label,
                active: _tab == i,
                onTap: () => setState(() => _tab = i),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tabContent(Fixture f) {
    switch (_tab) {
      case 0:
        return EventsTab(fixture: f);
      case 1:
        return _detailsTab(f);
      case 2:
        return LineupsTab(fixtureId: f.id);
      case 3:
        return StatisticsTab(fixture: f);
      case 4:
        return MatchStandingsTab(fixture: f);
      case 5:
        return _scoresTab(f);
      case 6:
        return NewsTab(fixtureId: f.id);
      case 7:
        return CommentsFeed(fixtureId: f.id);
      case 8:
        return _predictionTab(f);
      default:
        return _detailsTab(f);
    }
  }

  Widget _placeholder(_MatchTab tab, String subtitle) {
    return EmptyState(icon: tab.icon, title: tab.label, subtitle: subtitle);
  }

  // ------------------------------------------------------------- details tab
  Widget _detailsTab(Fixture f) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [_infoCard(f)],
    );
  }

  Widget _predictionTab(Fixture f) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [PredictionSection(fixture: f)],
    );
  }

  // ------------------------------------------------------------- scores tab
  Widget _scoresTab(Fixture f) {
    final periods = <(String, ScoreLine)>[
      (context.l10n.matchDetailPeriodFirstHalf, f.score.halftime),
      (context.l10n.matchDetailPeriodFullTime, f.score.fulltime),
      (context.l10n.matchDetailPeriodExtraTime, f.score.extratime),
      (context.l10n.matchDetailPeriodPenalties, f.score.penalty),
    ].where((p) => p.$2.home != null || p.$2.away != null).toList();

    if (periods.isEmpty) {
      return _placeholder(
          _tabsFor(context.l10n)[5], context.l10n.matchDetailScoresEmptySubtitle);
    }

    Widget teamName(String n) => Expanded(
          child: Text(n,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.tajawal(
                  size: 13,
                  weight: AppText.bold,
                  color: AppColors.textSubtleGreen)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        ClayCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  teamName(f.home.name),
                  const SizedBox(width: 110),
                  teamName(f.away.name),
                ],
              ),
              const SizedBox(height: 6),
              for (int i = 0; i < periods.length; i++) ...[
                const Divider(height: 1, color: AppColors.divider),
                _scoreRow(periods[i].$1, periods[i].$2),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _scoreRow(String label, ScoreLine s) {
    Widget val(int? v) => Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${v ?? '-'}',
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                  size: 18, weight: AppText.black, color: AppColors.textPrimary),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          val(s.home),
          SizedBox(
            width: 110,
            child: Text(label, textAlign: TextAlign.center, style: AppText.muted),
          ),
          val(s.away),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- score card
  Widget _scoreCard(Fixture f) {
    final s = f.status;
    final showScore = s.isFinished || s.isLive;
    final pill = s.isLive
        ? context.l10n.matchDetailStatusLive
        : s.isFinished
            ? context.l10n.matchDetailStatusFinished
            : context.l10n.matchDetailStatusNotStarted;
    return ClayCard(
      strong: true,
      radius: 26,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _bigTeam(f.home)),
              Expanded(
                child: Column(
                  children: [
                    if (showScore)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${f.home.goals ?? 0} - ${f.away.goals ?? 0}',
                          style: AppText.tajawal(
                            size: 36,
                            weight: AppText.black,
                            color: AppColors.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFmt.time(f.datetime, locale: 'ar'),
                          style: AppText.tajawal(
                            size: 22,
                            weight: AppText.extraBold,
                            color: AppColors.textSubtleGreen,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _statusPill(
                      s.isLive && s.elapsed != null ? "${s.elapsed}'" : pill,
                    ),
                  ],
                ),
              ),
              Expanded(child: _bigTeam(f.away)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            f.datetime == null
                ? ''
                : DateFmt.dateTime(f.datetime, locale: 'ar'),
            style: AppText.muted,
          ),
        ],
      ),
    );
  }

  Widget _bigTeam(FixtureTeam team) {
    final logo = assetUrl(team.logo);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/teams/${team.id}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: Clay.circle(AppColors.crest(_crestColor(team.id))),
            child: logo == null
                ? const Icon(Icons.star_rounded, color: Colors.white, size: 32)
                : NetworkImageBox(url: logo, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(
            team.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.tajawal(
              size: 15,
              weight: AppText.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- social row
  Widget _socialRow(Fixture f, FixtureSocial social) {
    return Container(
      decoration: Clay.card(radius: 22, gradient: AppColors.surface),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: () => _toggleLike(f),
              builder: (context, pressed) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    social.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: social.likedByMe
                        ? AppColors.logoutText
                        : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 5),
                  Text('${social.likes}', style: AppText.muted),
                ],
              ),
            ),
          ),
          _divider(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/fixtures/${f.id}/comments'),
              child: _stat(Icons.mode_comment_outlined, social.comments),
            ),
          ),
          _divider(),
          Expanded(
            child: Pressable(
              onTap: () => _share(f),
              builder: (context, pressed) =>
                  _stat(Icons.ios_share_rounded, social.shares),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 22),
        const SizedBox(height: 5),
        Text('$count', style: AppText.muted),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.infoDivider);

  // ---------------------------------------------------------------- info card
  Widget _infoCard(Fixture f) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(
        children: [
          _infoRow(
            Icons.emoji_events_outlined,
            context.l10n.matchDetailInfoTournament,
            f.league.name,
            onTap: () => context.push('/leagues/${f.league.id}'),
          ),
          if (f.league.round != null)
            _infoRow(
                Icons.flag_outlined, context.l10n.matchDetailInfoRound, f.league.round!),
          if (f.venue.name != null)
            _infoRow(
              Icons.stadium_outlined,
              context.l10n.matchDetailInfoStadium,
              [f.venue.name, f.venue.city].whereType<String>().join(' · '),
            ),
          if (f.status.long != null)
            _infoRow(
                Icons.info_outline, context.l10n.matchDetailInfoStatus, f.status.long!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text(label, style: AppText.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.tajawal(
                size: 14,
                weight: AppText.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left, size: 18, color: AppColors.chevron),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
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
