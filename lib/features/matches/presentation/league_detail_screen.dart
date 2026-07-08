import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/league.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'match_widgets.dart';
import 'standings_table.dart';

/// League detail (`/leagues/:id`) — tabs: الترتيب (standings), المباريات
/// (fixtures), الهدافون (top scorers). A season pill under the tab bar (shown
/// when the league has 2+ seasons) switches all three tabs to that season;
/// unselected → the backend's current-season default.
class LeagueDetailScreen extends ConsumerStatefulWidget {
  const LeagueDetailScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen> {
  int _tab = 0;

  /// Selected season YEAR; null → current season (backend default).
  int? _seasonYear;

  List<String> _tabLabels(BuildContext context) => [
        context.l10n.matchesNavTabStandings,
        context.l10n.navMatches,
        context.l10n.matchesNavTabScorers,
      ];

  @override
  Widget build(BuildContext context) {
    final id = widget.leagueId;
    final league = ref.watch(leagueDetailProvider(id)).valueOrNull;
    final title = league?.name ?? context.l10n.matchesNavLeagueTitle;
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Column(
              children: [
                DetailHeaderRow(title: title, fallbackRoute: '/leagues'),
                const SizedBox(height: 12),
                _tabBar(),
                if (league != null && league.seasons.length > 1) ...[
                  const SizedBox(height: 10),
                  _seasonPill(league),
                ],
              ],
            ),
          ),
          Expanded(child: _content(id)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ season picker
  Season? _selectedSeason(League league) {
    if (_seasonYear != null) {
      for (final s in league.seasons) {
        if (s.year == _seasonYear) return s;
      }
    }
    return league.currentSeason ??
        (league.seasons.isEmpty ? null : league.seasons.first);
  }

  Widget _seasonPill(League league) {
    final selected = _selectedSeason(league);
    final label = selected?.displayLabel ?? context.l10n.matchesNavSeason;
    return GestureDetector(
      onTap: () => _pickSeason(league),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: Clay.card(radius: 14, gradient: AppColors.surface),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded,
                size: 16, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(
              '${context.l10n.matchesNavSeason} $label',
              textDirection: TextDirection.ltr,
              style: AppText.tajawal(
                size: 13,
                weight: AppText.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSeason(League league) async {
    final selected = _selectedSeason(league);
    final picked = await showModalBottomSheet<Season>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.7),
          decoration: const BoxDecoration(
            color: AppColors.screenBgWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Text(sheetContext.l10n.matchesNavSelectSeason,
                  style: AppText.sectionHeader),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: league.seasons.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, i) {
                    final s = league.seasons[i];
                    final active = s.id == selected?.id;
                    return ListTile(
                      title: Text(
                        s.displayLabel,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: AppText.tajawal(
                          size: 15,
                          weight: active ? AppText.extraBold : AppText.bold,
                          color: active
                              ? AppColors.primaryGreen
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: s.isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.pillBg,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                context.l10n.matchesNavCurrentSeason,
                                style: AppText.tajawal(
                                  size: 12,
                                  weight: AppText.bold,
                                  color: AppColors.pillText,
                                ),
                              ),
                            )
                          : (active
                              ? const Icon(Icons.check_rounded,
                                  size: 20, color: AppColors.primaryGreen)
                              : null),
                      onTap: () => Navigator.of(context).pop(s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (picked != null && picked.year != null && mounted) {
      setState(() => _seasonYear = picked.year);
    }
  }

  Widget _tabBar() {
    final tabs = _tabLabels(context);
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: Clay.card(radius: 20, gradient: AppColors.surface),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AppChip(
                label: tabs[i],
                active: _tab == i,
                onTap: () => setState(() => _tab = i),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _content(int id) {
    switch (_tab) {
      case 1:
        return _fixturesTab(id);
      case 2:
        return _scorersTab(id);
      case 0:
      default:
        return _standingsTab(id);
    }
  }

  // ----------------------------------------------------------- standings tab
  Widget _standingsTab(int id) {
    final key = (id, _seasonYear);
    final async = ref.watch(standingsProvider(key));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(standingsProvider(key)),
      data: (rows) {
        if (rows.isEmpty) return EmptyState(title: context.l10n.matchesNavNoStandings);
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async => ref.invalidate(standingsProvider(key)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [StandingsTable(standings: rows)],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------- fixtures tab
  Widget _fixturesTab(int id) {
    final key = (id, _seasonYear);
    final async = ref.watch(leagueFixturesProvider(key));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(leagueFixturesProvider(key)),
      data: (fixtures) {
        if (fixtures.isEmpty) return EmptyState(title: context.l10n.matchesNavNoMatches);
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async => ref.invalidate(leagueFixturesProvider(key)),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            itemCount: fixtures.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => FixtureCard(fixture: fixtures[i]),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------- scorers tab
  Widget _scorersTab(int id) {
    final key = (id, _seasonYear);
    final async = ref.watch(topScorersProvider(key));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(topScorersProvider(key)),
      data: (scorers) {
        if (scorers.isEmpty) return EmptyState(title: context.l10n.matchesNavNoScorers);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          itemCount: scorers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final s = scorers[i];
            return ClayCard(
              radius: 18,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              onTap: s.playerId > 0
                  ? () => context.push('/players/${s.playerId}')
                  : null,
              child: Row(
                children: [
                  TeamCrest(
                      teamId: s.team?.id ?? s.playerId,
                      logo: s.team?.logo,
                      size: 40,
                      iconSize: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.playerName,
                            style: AppText.tajawal(
                                size: 15,
                                weight: AppText.bold,
                                color: AppColors.textPrimary)),
                        if (s.team != null) ...[
                          const SizedBox(height: 2),
                          Text(s.team!.name, style: AppText.muted),
                        ],
                      ],
                    ),
                  ),
                  Text('${s.goals}',
                      style: AppText.tajawal(
                          size: 18,
                          weight: AppText.black,
                          color: AppColors.primaryGreen)),
                  const SizedBox(width: 4),
                  Text(context.l10n.matchesNavGoals, style: AppText.muted),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

