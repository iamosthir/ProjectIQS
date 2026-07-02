import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
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
/// (fixtures), الهدافون (top scorers). `?season` omitted → current season.
class LeagueDetailScreen extends ConsumerStatefulWidget {
  const LeagueDetailScreen({super.key, required this.leagueId});

  final int leagueId;

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen> {
  int _tab = 0;

  List<String> _tabLabels(BuildContext context) => [
        context.l10n.matchesNavTabStandings,
        context.l10n.navMatches,
        context.l10n.matchesNavTabScorers,
      ];

  @override
  Widget build(BuildContext context) {
    final id = widget.leagueId;
    final title = ref.watch(leagueDetailProvider(id)).valueOrNull?.name ??
        context.l10n.matchesNavLeagueTitle;
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
              ],
            ),
          ),
          Expanded(child: _content(id)),
        ],
      ),
    );
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
    final async = ref.watch(standingsProvider((id, null)));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(standingsProvider((id, null))),
      data: (rows) {
        if (rows.isEmpty) return EmptyState(title: context.l10n.matchesNavNoStandings);
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async => ref.invalidate(standingsProvider((id, null))),
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
    final async = ref.watch(leagueFixturesProvider(id));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(leagueFixturesProvider(id)),
      data: (fixtures) {
        if (fixtures.isEmpty) return EmptyState(title: context.l10n.matchesNavNoMatches);
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async => ref.invalidate(leagueFixturesProvider(id)),
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
    final async = ref.watch(topScorersProvider((id, null)));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(topScorersProvider((id, null))),
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

