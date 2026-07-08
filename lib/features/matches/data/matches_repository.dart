import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/api_client.dart';

import 'comment.dart';
import 'fixture.dart';
import 'fixture_extras.dart';
import 'fixture_news.dart';
import 'league.dart';
import 'prediction.dart';
import 'standing.dart';
import 'team.dart';

/// All `/fixtures*` and `/leagues*` reads, plus like/share writes. The Matches
/// module is throttled 60/min/user — callers should not poll faster than ~60s.
class MatchesRepository {
  MatchesRepository(this._api);

  final ApiClient _api;

  Future<Paginated<Fixture>> fixtures({
    String? date,
    int? league,
    int? team,
    String? statusGroup,
    int page = 1,
    int perPage = 20,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (date != null) query['date'] = date;
    if (league != null) query['league'] = league;
    if (team != null) query['team'] = team;
    if (statusGroup != null) query['status_group'] = statusGroup;
    return _api.getPaged(
      '/fixtures',
      query: query,
      parseItem: Fixture.fromJson,
    );
  }

  Future<List<Fixture>> liveFixtures() => _api.get(
        '/fixtures/live',
        parse: (d) => (d as List)
            .map((e) => Fixture.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<Fixture> fixture(int id) => _api.get(
        '/fixtures/$id',
        parse: (d) => Fixture.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<List<League>> leagues({bool? isIraqi}) => _api.get(
        '/leagues',
        // Only send the (truthy) filter when Iraqi-only is wanted; for "all"
        // omit it (the API doesn't define an is_iraqi=0 negation).
        query: isIraqi == true ? {'is_iraqi': 1} : null,
        parse: (d) => (d as List)
            .map((e) => League.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<League> league(int id) => _api.get(
        '/leagues/$id',
        parse: (d) => League.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// `?season` is the season YEAR (e.g. 2025), matched against `Season.year` —
  /// NOT a season id. Omit to default to the current season.
  Future<List<Standing>> standings(int leagueId, {int? season}) => _api.get(
        '/leagues/$leagueId/standings',
        query: season == null ? null : {'season': season},
        parse: (d) => (d as List)
            .map((e) => Standing.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  /// `?season` is the season YEAR (e.g. 2025); omit for all league fixtures.
  Future<Paginated<Fixture>> leagueFixtures(
    int leagueId, {
    int page = 1,
    int? season,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': 50};
    if (season != null) query['season'] = season;
    return _api.getPaged(
      '/leagues/$leagueId/fixtures',
      query: query,
      parseItem: Fixture.fromJson,
    );
  }

  Future<List<TopScorer>> topScorers(int leagueId, {int? season}) => _api.get(
        '/leagues/$leagueId/top-scorers',
        query: season == null ? null : {'season': season},
        parse: (d) => (d as List)
            .map((e) => TopScorer.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<Team> team(int id) => _api.get(
        '/teams/$id',
        parse: (d) => Team.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<Paginated<Fixture>> teamFixtures(
    int id, {
    int page = 1,
    String? statusGroup,
  }) {
    final query = <String, dynamic>{'page': page, 'per_page': 50};
    if (statusGroup != null) query['status_group'] = statusGroup;
    return _api.getPaged(
      '/teams/$id/fixtures',
      query: query,
      parseItem: Fixture.fromJson,
    );
  }

  Future<List<Player>> squad(int teamId) => _api.get(
        '/teams/$teamId/squad',
        parse: (d) => (d as List)
            .map((e) => Player.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<Player> player(int id) => _api.get(
        '/players/$id',
        parse: (d) => Player.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<void> like(int fixtureId) =>
      _api.post('/fixtures/$fixtureId/like', parse: (_) {});

  Future<void> unlike(int fixtureId) =>
      _api.delete('/fixtures/$fixtureId/like', parse: (_) {});

  Future<void> share(int fixtureId) =>
      _api.post('/fixtures/$fixtureId/share', parse: (_) {});

  // ---- fixture detail tabs (events / lineups / statistics) ----

  Future<List<FixtureEvent>> fixtureEvents(int fixtureId) => _api.get(
        '/fixtures/$fixtureId/events',
        parse: (d) => (d as List)
            .map((e) =>
                FixtureEvent.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<List<Lineup>> fixtureLineups(int fixtureId) => _api.get(
        '/fixtures/$fixtureId/lineups',
        parse: (d) => (d as List)
            .map((e) => Lineup.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<List<MatchStatistic>> fixtureStatistics(int fixtureId) => _api.get(
        '/fixtures/$fixtureId/statistics',
        parse: (d) => (d as List)
            .map((e) =>
                MatchStatistic.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Future<Paginated<FixtureNews>> fixtureNews(int fixtureId, {int page = 1}) =>
      _api.getPaged(
        '/fixtures/$fixtureId/news',
        query: {'page': page, 'per_page': 20},
        parseItem: FixtureNews.fromJson,
      );

  // ---- predictions ----

  Future<PredictionSummary> predictionsSummary(int fixtureId) => _api.get(
        '/fixtures/$fixtureId/predictions/summary',
        parse: (d) =>
            PredictionSummary.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Upsert the caller's scoreline prediction (`{home, away}`, each 0–99).
  /// 422 when predictions are closed (after kickoff).
  Future<PredictionEntry> predict(int fixtureId,
          {required int home, required int away}) =>
      _api.post(
        '/fixtures/$fixtureId/predictions',
        data: {'home': home, 'away': away},
        parse: (d) =>
            PredictionEntry.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<Paginated<PredictionEntry>> correctPredictions(int fixtureId,
          {int page = 1}) =>
      _api.getPaged(
        '/fixtures/$fixtureId/predictions/correct',
        query: {'page': page, 'per_page': 20},
        parseItem: PredictionEntry.fromJson,
      );

  Future<void> likePrediction(int predictionId) =>
      _api.post('/predictions/$predictionId/like', parse: (_) {});

  Future<void> unlikePrediction(int predictionId) =>
      _api.delete('/predictions/$predictionId/like', parse: (_) {});

  // ---- comments ----

  Future<Paginated<Comment>> comments(
    int fixtureId, {
    String context = 'match',
    String sort = 'newest',
    int page = 1,
  }) =>
      _api.getPaged(
        '/fixtures/$fixtureId/comments',
        query: {
          'context': context,
          'sort': sort,
          'page': page,
          'per_page': 20,
        },
        parseItem: Comment.fromJson,
      );

  Future<Comment> postComment(
    int fixtureId, {
    required String body,
    String context = 'match',
    int? parentId,
  }) {
    final data = <String, dynamic>{'body': body, 'context': context};
    if (parentId != null) data['parent_id'] = parentId;
    return _api.post(
      '/fixtures/$fixtureId/comments',
      data: data,
      parse: (d) => Comment.fromJson((d as Map).cast<String, dynamic>()),
    );
  }

  Future<Paginated<Comment>> replies(int commentId, {int page = 1}) =>
      _api.getPaged(
        '/comments/$commentId/replies',
        query: {'page': page, 'per_page': 20},
        parseItem: Comment.fromJson,
      );

  Future<void> likeComment(int commentId) =>
      _api.post('/comments/$commentId/like', parse: (_) {});

  Future<void> unlikeComment(int commentId) =>
      _api.delete('/comments/$commentId/like', parse: (_) {});

  Future<Comment> editComment(int commentId, String body) => _api.put(
        '/comments/$commentId',
        data: {'body': body},
        parse: (d) => Comment.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<void> deleteComment(int commentId) =>
      _api.delete('/comments/$commentId', parse: (_) {});
}
