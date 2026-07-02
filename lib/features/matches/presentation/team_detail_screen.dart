import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/team.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'match_widgets.dart';

/// Team profile (`/teams/:id`) — info + tabs المباريات (fixtures) / التشكيلة
/// (squad, grouped by position, sorted by shirt number).
class TeamDetailScreen extends ConsumerStatefulWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final int teamId;

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  int _tab = 0;

  List<String> _tabLabels(BuildContext context) => [
        context.l10n.navMatches,
        context.l10n.matchesNavTabSquad,
      ];

  // Group ordering for squad positions (API position keys).
  static const _positionOrder = ['Goalkeeper', 'Defender', 'Midfielder', 'Attacker'];

  // Localized labels for squad positions, keyed by the API position value.
  static Map<String, String> _positionLabels(AppLocalizations l) => {
        'Goalkeeper': l.matchesNavPosGoalkeeper,
        'Defender': l.matchesNavPosDefender,
        'Midfielder': l.matchesNavPosMidfielder,
        'Attacker': l.matchesNavPosAttacker,
        'أخرى': l.matchesNavPosOther,
      };

  @override
  Widget build(BuildContext context) {
    final id = widget.teamId;
    final async = ref.watch(teamProvider(id));
    final title = async.valueOrNull?.name ?? context.l10n.matchesNavTeamTitle;
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: DetailHeaderRow(title: title, fallbackRoute: '/leagues'),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(teamProvider(id)),
              data: (team) => Column(
                children: [
                  _infoCard(team),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                    child: _tabBar(),
                  ),
                  Expanded(child: _tab == 0 ? _fixturesTab(id) : _squadTab(id)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Team team) {
    final bits = <(IconData, String)>[
      if (team.country != null) (Icons.flag_outlined, team.country!),
      if (team.foundedYear != null)
        (Icons.event_outlined, context.l10n.matchesNavFoundedYear(team.foundedYear!)),
      if (team.venueName != null) (Icons.stadium_outlined, team.venueName!),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
      child: ClayCard(
        strong: true,
        radius: 24,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Column(
          children: [
            TeamCrest(teamId: team.id, logo: team.logo, size: 66, iconSize: 32),
            const SizedBox(height: 12),
            Text(
              team.name,
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                size: 18,
                weight: AppText.extraBold,
                color: AppColors.textPrimary,
              ),
            ),
            if (bits.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final b in bits)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.$1, size: 16, color: AppColors.primaryGreen),
                        const SizedBox(width: 6),
                        Text(b.$2, style: AppText.muted),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
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

  Widget _fixturesTab(int id) {
    final async = ref.watch(teamFixturesProvider(id));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(teamFixturesProvider(id)),
      data: (fixtures) {
        if (fixtures.isEmpty) return EmptyState(title: context.l10n.matchesNavNoMatches);
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async => ref.invalidate(teamFixturesProvider(id)),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            itemCount: fixtures.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) => FixtureCard(fixture: fixtures[i]),
          ),
        );
      },
    );
  }

  Widget _squadTab(int id) {
    final async = ref.watch(squadProvider(id));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(squadProvider(id)),
      data: (players) {
        if (players.isEmpty) return EmptyState(title: context.l10n.matchesNavNoSquad);
        final positionLabels = _positionLabels(context.l10n);
        // Group by position in a fixed order; sort each group by shirt number.
        final groups = <String, List<Player>>{};
        for (final p in players) {
          groups.putIfAbsent(p.position ?? 'أخرى', () => []).add(p);
        }
        for (final list in groups.values) {
          list.sort((a, b) => (a.number ?? 999).compareTo(b.number ?? 999));
        }
        final orderedKeys = [
          ..._positionOrder.where(groups.containsKey),
          ...groups.keys.where((k) => !_positionOrder.contains(k)),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            for (final key in orderedKeys) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                child: Text(
                  positionLabels[key] ?? key,
                  style: AppText.tajawal(
                    size: 14,
                    weight: AppText.extraBold,
                    color: AppColors.sectionLabel,
                  ),
                ),
              ),
              Container(
                decoration: Clay.card(radius: 20, gradient: AppColors.surface),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (int i = 0; i < groups[key]!.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider),
                      _PlayerRow(player: groups[key]![i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/players/${player.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  player.number == null ? '–' : '${player.number}',
                  textAlign: TextAlign.center,
                  style: AppText.tajawal(
                    size: 15,
                    weight: AppText.extraBold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 15,
                    weight: AppText.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (player.isInjured)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.healing_outlined,
                      size: 18, color: AppColors.logoutText),
                ),
              const Icon(Icons.chevron_left, color: AppColors.chevron, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
