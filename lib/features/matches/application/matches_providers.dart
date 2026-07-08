import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/matches/data/fixture.dart';
import 'package:iqs_flutter/features/matches/data/fixture_extras.dart';
import 'package:iqs_flutter/features/matches/data/league.dart';
import 'package:iqs_flutter/features/matches/data/matches_repository.dart';
import 'package:iqs_flutter/features/matches/data/prediction.dart';
import 'package:iqs_flutter/features/matches/data/standing.dart';
import 'package:iqs_flutter/features/matches/data/team.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>(
  (ref) => MatchesRepository(ref.watch(apiClientProvider)),
);

/// Immutable key for the fixtures family provider (so identical queries share a
/// cache entry).
@immutable
class FixturesQuery {
  const FixturesQuery({this.date, this.statusGroup, this.league, this.team});
  final String? date;
  final String? statusGroup;
  final int? league;
  final int? team;

  @override
  bool operator ==(Object other) =>
      other is FixturesQuery &&
      other.date == date &&
      other.statusGroup == statusGroup &&
      other.league == league &&
      other.team == team;

  @override
  int get hashCode => Object.hash(date, statusGroup, league, team);
}

/// First page of fixtures for a query (the feed sections fetch up to per_page=50
/// — seed data fits in one page; full infinite-scroll-append can layer on later).
final fixturesProvider =
    FutureProvider.family<Paginated<Fixture>, FixturesQuery>(
  (ref, q) => ref.watch(matchesRepositoryProvider).fixtures(
        date: q.date,
        statusGroup: q.statusGroup,
        league: q.league,
        team: q.team,
        perPage: 50,
      ),
);

final liveFixturesProvider = FutureProvider<List<Fixture>>(
  (ref) => ref.watch(matchesRepositoryProvider).liveFixtures(),
);

/// Auto-dispose so re-entering a previously-viewed fixture replays
/// loading→data — which re-fires the detail screen's polling listener (a cached
/// value would not) — and frees detail payloads when the screen is popped.
final fixtureDetailProvider = FutureProvider.autoDispose.family<Fixture, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).fixture(id),
);

/// Match-detail tab data (autoDispose family by fixtureId). The 60s live poll
/// on the detail screen invalidates these alongside the fixture.
final fixtureEventsProvider =
    FutureProvider.autoDispose.family<List<FixtureEvent>, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).fixtureEvents(id),
);

final fixtureLineupsProvider =
    FutureProvider.autoDispose.family<List<Lineup>, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).fixtureLineups(id),
);

final fixtureStatisticsProvider =
    FutureProvider.autoDispose.family<List<MatchStatistic>, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).fixtureStatistics(id),
);

/// Leagues list; pass `true` for Iraqi-only (the matches/الفرق entry).
final leaguesProvider = FutureProvider.family<List<League>, bool?>(
  (ref, isIraqi) => ref.watch(matchesRepositoryProvider).leagues(isIraqi: isIraqi),
);

final leagueDetailProvider = FutureProvider.family<League, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).league(id),
);

/// Key: (leagueId, season-year). `season` null → current season.
final standingsProvider =
    FutureProvider.family<List<Standing>, (int, int?)>(
  (ref, key) =>
      ref.watch(matchesRepositoryProvider).standings(key.$1, season: key.$2),
);

/// Key: (leagueId, season-year). `season` null → all league fixtures.
final leagueFixturesProvider =
    FutureProvider.family<List<Fixture>, (int, int?)>((ref, key) async {
  final page = await ref
      .watch(matchesRepositoryProvider)
      .leagueFixtures(key.$1, season: key.$2);
  return page.items;
});

final topScorersProvider =
    FutureProvider.family<List<TopScorer>, (int, int?)>(
  (ref, key) =>
      ref.watch(matchesRepositoryProvider).topScorers(key.$1, season: key.$2),
);

final teamProvider = FutureProvider.family<Team, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).team(id),
);

final teamFixturesProvider =
    FutureProvider.family<List<Fixture>, int>((ref, teamId) async {
  final page = await ref.watch(matchesRepositoryProvider).teamFixtures(teamId);
  return page.items;
});

final squadProvider = FutureProvider.family<List<Player>, int>(
  (ref, teamId) => ref.watch(matchesRepositoryProvider).squad(teamId),
);

final playerProvider = FutureProvider.family<Player, int>(
  (ref, id) => ref.watch(matchesRepositoryProvider).player(id),
);

/// Auto-dispose so re-voting / re-opening refetches fresh vote shares.
final predictionsSummaryProvider =
    FutureProvider.autoDispose.family<PredictionSummary, int>(
  (ref, fixtureId) =>
      ref.watch(matchesRepositoryProvider).predictionsSummary(fixtureId),
);
