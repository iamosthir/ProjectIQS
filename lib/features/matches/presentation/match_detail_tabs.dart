import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/fixture.dart';
import 'package:iqs_flutter/features/matches/data/fixture_extras.dart';
import 'package:iqs_flutter/features/matches/data/fixture_news.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'standings_table.dart';

// ============================================================ Events tab =====

/// Match timeline (`/fixtures/:id/events`) — a home/away-aligned event list.
class EventsTab extends ConsumerWidget {
  const EventsTab({super.key, required this.fixture});
  final Fixture fixture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fixtureEventsProvider(fixture.id));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(fixtureEventsProvider(fixture.id)),
      data: (events) => events.isEmpty
          ? EmptyState(
              icon: Icons.timeline,
              title: context.l10n.matchDetailEventsEmptyTitle,
              subtitle: context.l10n.matchDetailEventsEmptySubtitle)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) =>
                  _EventRow(event: events[i], homeTeamId: fixture.home.id),
            ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.homeTeamId});
  final FixtureEvent event;
  final int homeTeamId;

  @override
  Widget build(BuildContext context) {
    // Team-less lifecycle events (kickoff / half_end / match_end / VAR) carry a
    // null team_id — render them centered rather than on the away side.
    if (event.teamId == null) return _neutralRow();
    final isHome = event.teamId == homeTeamId;
    final content = _content(context.l10n, alignEnd: !isHome);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: isHome ? content : const SizedBox.shrink()),
        _minuteBadge(),
        Expanded(child: isHome ? const SizedBox.shrink() : content),
      ],
    );
  }

  Widget _neutralRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _EventIcon(event: event),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            event.player.hasName ? event.player.name! : (event.detail ?? '—'),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.muted,
          ),
        ),
        _minuteBadge(),
      ],
    );
  }

  /// Secondary line: assist for goals, the outgoing player for substitutions,
  /// the card detail for cards. (Assists belong to goals — never label a sub as
  /// a pass.)
  String? _subLabel(AppLocalizations l) {
    if (event.isSubst && event.assist.hasName) {
      return l.matchDetailEventSubOut(event.assist.name!);
    }
    if (event.isGoal && event.assist.hasName) {
      return l.matchDetailEventAssist(event.assist.name!);
    }
    if (event.isCard && (event.detail?.isNotEmpty ?? false)) return event.detail;
    return null;
  }

  Widget _minuteBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          event.minuteLabel.isEmpty ? '—' : event.minuteLabel,
          style: AppText.tajawal(
              size: 12, weight: AppText.extraBold, color: AppColors.pillText),
        ),
      ),
    );
  }

  Widget _content(AppLocalizations l, {required bool alignEnd}) {
    final crossAxis =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final icon = _EventIcon(event: event);
    final sub = _subLabel(l);
    final texts = Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.player.hasName ? event.player.name! : (event.detail ?? '—'),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.tajawal(
              size: 14, weight: AppText.bold, color: AppColors.textPrimary),
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.muted,
          ),
        ],
      ],
    );
    final children = alignEnd
        ? [Flexible(child: texts), const SizedBox(width: 8), icon]
        : [icon, const SizedBox(width: 8), Flexible(child: texts)];
    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.event});
  final FixtureEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.isCard) {
      return Container(
        width: 13,
        height: 17,
        decoration: BoxDecoration(
          color: event.isRedCard
              ? const Color(0xFFD64545)
              : const Color(0xFFE9C43B),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    final IconData icon;
    Color color = AppColors.primaryGreen;
    switch (event.type) {
      case 'goal':
      case 'penalty':
        icon = Icons.sports_soccer;
        break;
      case 'subst':
        icon = Icons.sync_alt;
        break;
      case 'var':
        icon = Icons.tv_outlined;
        color = AppColors.textMuted;
        break;
      default:
        icon = Icons.sports;
        color = AppColors.textMuted;
    }
    return Icon(icon, size: 20, color: color);
  }
}

// =========================================================== Lineups tab =====

/// Lineups (`/fixtures/:id/lineups`) — one card per team: formation + coach,
/// starters, substitutes.
class LineupsTab extends ConsumerWidget {
  const LineupsTab({super.key, required this.fixtureId});
  final int fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fixtureLineupsProvider(fixtureId));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(fixtureLineupsProvider(fixtureId)),
      data: (lineups) => lineups.isEmpty
          ? EmptyState(
              icon: Icons.groups_outlined,
              title: context.l10n.matchDetailLineupsEmptyTitle,
              subtitle: context.l10n.matchDetailLineupsEmptySubtitle)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              itemCount: lineups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _LineupCard(lineup: lineups[i]),
            ),
    );
  }
}

class _LineupCard extends StatelessWidget {
  const _LineupCard({required this.lineup});
  final Lineup lineup;

  @override
  Widget build(BuildContext context) {
    final logo = assetUrl(lineup.teamLogo);
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: Clay.circle(AppColors.avatar),
                child: logo == null
                    ? const Icon(Icons.shield, color: Colors.white, size: 20)
                    : NetworkImageBox(url: logo, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lineup.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.tajawal(
                            size: 16,
                            weight: AppText.extraBold,
                            color: AppColors.textPrimary)),
                    if (lineup.formation != null ||
                        (lineup.coachName?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (lineup.formation != null) lineup.formation,
                          if (lineup.coachName?.isNotEmpty ?? false)
                            context.l10n.matchDetailLineupCoach(lineup.coachName!),
                        ].whereType<String>().join('  ·  '),
                        style: AppText.muted,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (lineup.startXI.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(context.l10n.matchDetailLineupStarters, style: AppText.groupLabel),
            const SizedBox(height: 6),
            for (final p in lineup.startXI) _PlayerRow(player: p),
          ],
          if (lineup.substitutes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(context.l10n.matchDetailLineupSubstitutes, style: AppText.groupLabel),
            const SizedBox(height: 6),
            for (final p in lineup.substitutes) _PlayerRow(player: p),
          ],
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});
  final LineupPlayer player;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              player.number?.toString() ?? '–',
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                  size: 13,
                  weight: AppText.extraBold,
                  color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(player.name ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowLabel),
          ),
          if (player.position != null && player.position!.isNotEmpty)
            Text(player.position!, style: AppText.muted),
        ],
      ),
    );
  }
}

// ======================================================== Statistics tab =====

/// Statistics (`/fixtures/:id/statistics`) — home vs away comparison bars,
/// paired by stat type.
class StatisticsTab extends ConsumerWidget {
  const StatisticsTab({super.key, required this.fixture});
  final Fixture fixture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fixtureStatisticsProvider(fixture.id));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(fixtureStatisticsProvider(fixture.id)),
      data: (stats) {
        final rows = _pair(stats);
        if (rows.isEmpty) {
          return EmptyState(
              icon: Icons.bar_chart_rounded,
              title: context.l10n.matchDetailStatsEmptyTitle,
              subtitle: context.l10n.matchDetailStatsEmptySubtitle);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            ClayCard(
              radius: 22,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.divider),
                    _StatRow(row: rows[i]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Pairs the flat per-team stats into (type, homeValue, awayValue) rows,
  /// preserving first-seen order.
  List<_StatPair> _pair(List<MatchStatistic> stats) {
    final order = <String>[];
    final home = <String, MatchStatistic>{};
    final away = <String, MatchStatistic>{};
    for (final s in stats) {
      if (!order.contains(s.type)) order.add(s.type);
      if (s.teamId == fixture.home.id) {
        home[s.type] = s;
      } else if (s.teamId == fixture.away.id) {
        away[s.type] = s;
      }
    }
    return [
      for (final type in order)
        _StatPair(type: type, home: home[type], away: away[type]),
    ];
  }
}

class _StatPair {
  const _StatPair({required this.type, this.home, this.away});
  final String type;
  final MatchStatistic? home;
  final MatchStatistic? away;
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.row});
  final _StatPair row;

  @override
  Widget build(BuildContext context) {
    final hn = row.home?.valueNumeric ?? 0;
    final an = row.away?.valueNumeric ?? 0;
    final total = hn + an;
    final homeFrac = total > 0 ? hn / total : 0.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(row.home?.value ?? '—',
                  style: AppText.tajawal(
                      size: 14,
                      weight: AppText.extraBold,
                      color: AppColors.textPrimary)),
              Expanded(
                child: Text(_label(context.l10n, row.type),
                    textAlign: TextAlign.center, style: AppText.muted)),
              Text(row.away?.value ?? '—',
                  style: AppText.tajawal(
                      size: 14,
                      weight: AppText.extraBold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeFrac * 1000).round().clamp(1, 1000),
                    child: Container(color: AppColors.primaryGreen),
                  ),
                  Expanded(
                    flex: ((1 - homeFrac) * 1000).round().clamp(1, 1000),
                    child: Container(color: AppColors.infoDivider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(AppLocalizations l, String type) {
    final map = {
      'Ball Possession': l.matchDetailStatBallPossession,
      'Total Shots': l.matchDetailStatTotalShots,
      'Shots on Goal': l.matchDetailStatShotsOnGoal,
      'Shots off Goal': l.matchDetailStatShotsOffGoal,
      'Corner Kicks': l.matchDetailStatCornerKicks,
      'Offsides': l.matchDetailStatOffsides,
      'Fouls': l.matchDetailStatFouls,
      'Yellow Cards': l.matchDetailStatYellowCards,
      'Red Cards': l.matchDetailStatRedCards,
      'Goalkeeper Saves': l.matchDetailStatGoalkeeperSaves,
      'Passes': l.matchDetailStatPasses,
      'Passes accurate': l.matchDetailStatPassesAccurate,
    };
    return map[type] ?? type;
  }
}

// ========================================================= Standings tab =====

/// The fixture's league standings (`/leagues/:leagueId/standings`), with the two
/// teams highlighted.
class MatchStandingsTab extends ConsumerWidget {
  const MatchStandingsTab({super.key, required this.fixture});
  final Fixture fixture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (fixture.league.id, null as int?);
    final async = ref.watch(standingsProvider(key));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(standingsProvider(key)),
      data: (rows) => rows.isEmpty
          ? EmptyState(
              icon: Icons.format_list_numbered,
              title: context.l10n.matchDetailStandingsEmptyTitle)
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                StandingsTable(
                  standings: rows,
                  highlightTeamIds: {fixture.home.id, fixture.away.id},
                ),
              ],
            ),
    );
  }
}

// ============================================================== News tab =====

/// Match news (`GET /fixtures/:id/news`). Tap → external source if a `url` is
/// present, else the in-app article.
class NewsTab extends ConsumerWidget {
  const NewsTab({super.key, required this.fixtureId});
  final int fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedListView<FixtureNews>(
      loader: (page) =>
          ref.read(matchesRepositoryProvider).fixtureNews(fixtureId, page: page),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      emptyTitle: context.l10n.matchDetailNewsEmptyTitle,
      emptySubtitle: context.l10n.matchDetailNewsEmptySubtitle,
      itemBuilder: (context, news, _) =>
          _NewsCard(news: news, fixtureId: fixtureId),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.fixtureId});
  final FixtureNews news;
  final int fixtureId;

  Future<void> _open(BuildContext context) async {
    if (news.hasExternalUrl) {
      final uri = Uri.tryParse(news.url!);
      if (uri != null && uri.hasScheme) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {/* ignore */}
      }
      return;
    }
    context.push('/fixtures/$fixtureId/news/${news.id}', extra: news);
  }

  @override
  Widget build(BuildContext context) {
    final cover = assetUrl(news.cover);
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      onTap: () => _open(context),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 104,
              height: 82,
              child: cover == null
                  ? Container(
                      color: const Color(0xFFEAF2EC),
                      alignment: Alignment.center,
                      child: const Icon(Icons.article_outlined,
                          color: AppColors.primaryGreen))
                  : NetworkImageBox(url: cover, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tajawal(
                        size: 15,
                        weight: AppText.extraBold,
                        color: AppColors.textPrimary,
                        height: 1.4)),
                if (news.excerpt != null && news.excerpt!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(news.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.muted),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (news.source != null && news.source!.isNotEmpty) ...[
                      Flexible(
                        child: Text(news.source!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.muted),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (news.publishedAt != null)
                      Text(DateFmt.relative(news.publishedAt!),
                          style: AppText.muted),
                    if (news.hasExternalUrl) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.open_in_new,
                          size: 13, color: AppColors.chevron),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
