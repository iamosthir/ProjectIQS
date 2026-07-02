import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

enum FixtureStatusGroup { scheduled, live, finished, postponed, cancelled, unknown }

FixtureStatusGroup _statusGroupFrom(String? s) {
  switch (s) {
    case 'scheduled':
      return FixtureStatusGroup.scheduled;
    case 'live':
      return FixtureStatusGroup.live;
    case 'finished':
      return FixtureStatusGroup.finished;
    case 'postponed':
      return FixtureStatusGroup.postponed;
    case 'cancelled':
      return FixtureStatusGroup.cancelled;
    default:
      return FixtureStatusGroup.unknown;
  }
}

/// Lightweight league reference embedded in a fixture (not the full [League]).
@immutable
class FixtureLeagueRef {
  const FixtureLeagueRef({required this.id, required this.name, this.logo, this.round});
  final int id;
  final String name;
  final String? logo;
  final String? round;

  factory FixtureLeagueRef.fromJson(Map<String, dynamic> j) => FixtureLeagueRef(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        logo: j['logo'] as String?,
        round: j['round'] as String?,
      );
}

@immutable
class FixtureStatus {
  const FixtureStatus({required this.group, this.short, this.long, this.elapsed});
  final FixtureStatusGroup group;
  final String? short;
  final String? long;
  final int? elapsed;

  bool get isLive => group == FixtureStatusGroup.live;
  bool get isFinished => group == FixtureStatusGroup.finished;
  bool get isScheduled => group == FixtureStatusGroup.scheduled;

  factory FixtureStatus.fromJson(Map<String, dynamic> j) => FixtureStatus(
        group: _statusGroupFrom(j['group']?.toString()),
        short: j['short'] as String?,
        long: j['long'] as String?,
        elapsed: (j['elapsed'] as num?)?.toInt(),
      );
}

@immutable
class FixtureTeam {
  const FixtureTeam({
    required this.id,
    required this.name,
    this.logo,
    this.goals,
    this.winner,
  });
  final int id;
  final String name;
  final String? logo;
  final int? goals;
  final bool? winner;

  factory FixtureTeam.fromJson(Map<String, dynamic> j) => FixtureTeam(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        logo: j['logo'] as String?,
        goals: (j['goals'] as num?)?.toInt(),
        winner: j['winner'] as bool?,
      );
}

@immutable
class Venue {
  const Venue({this.id, this.name, this.city});
  final int? id;
  final String? name;
  final String? city;

  factory Venue.fromJson(Map<String, dynamic>? j) => j == null
      ? const Venue()
      : Venue(
          id: (j['id'] as num?)?.toInt(),
          name: j['name'] as String?,
          city: j['city'] as String?,
        );
}

@immutable
class ScoreLine {
  const ScoreLine({this.home, this.away});
  final int? home;
  final int? away;
  factory ScoreLine.fromJson(Map<String, dynamic>? j) => j == null
      ? const ScoreLine()
      : ScoreLine(
          home: (j['home'] as num?)?.toInt(),
          away: (j['away'] as num?)?.toInt(),
        );
}

@immutable
class FixtureScore {
  const FixtureScore({
    this.halftime = const ScoreLine(),
    this.fulltime = const ScoreLine(),
    this.extratime = const ScoreLine(),
    this.penalty = const ScoreLine(),
  });
  final ScoreLine halftime;
  final ScoreLine fulltime;
  final ScoreLine extratime;
  final ScoreLine penalty;

  factory FixtureScore.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const FixtureScore();
    return FixtureScore(
      halftime: ScoreLine.fromJson((j['halftime'] as Map?)?.cast<String, dynamic>()),
      fulltime: ScoreLine.fromJson((j['fulltime'] as Map?)?.cast<String, dynamic>()),
      extratime: ScoreLine.fromJson((j['extratime'] as Map?)?.cast<String, dynamic>()),
      penalty: ScoreLine.fromJson((j['penalty'] as Map?)?.cast<String, dynamic>()),
    );
  }
}

@immutable
class FixtureSocial {
  const FixtureSocial({
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.likedByMe = false,
  });
  final int likes;
  final int comments;
  final int shares;
  final bool likedByMe;

  factory FixtureSocial.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const FixtureSocial();
    return FixtureSocial(
      likes: (j['likes'] as num?)?.toInt() ?? 0,
      comments: (j['comments'] as num?)?.toInt() ?? 0,
      shares: (j['shares'] as num?)?.toInt() ?? 0,
      likedByMe: j['liked_by_me'] == true,
    );
  }

  FixtureSocial copyWith({int? likes, int? shares, bool? likedByMe}) =>
      FixtureSocial(
        likes: likes ?? this.likes,
        comments: comments,
        shares: shares ?? this.shares,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}

@immutable
class FixtureHas {
  const FixtureHas({
    this.events = false,
    this.lineups = false,
    this.statistics = false,
  });
  final bool events;
  final bool lineups;
  final bool statistics;

  factory FixtureHas.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const FixtureHas();
    return FixtureHas(
      events: j['events'] == true,
      lineups: j['lineups'] == true,
      statistics: j['statistics'] == true,
    );
  }
}

/// Crowd-prediction summary embedded in the fixture detail payload.
@immutable
class FixturePrediction {
  const FixturePrediction({
    this.total = 0,
    this.homePercent = 0,
    this.drawPercent = 0,
    this.awayPercent = 0,
    this.isOpen = false,
    this.myPrediction,
  });
  final int total;
  final double homePercent;
  final double drawPercent;
  final double awayPercent;
  final bool isOpen;

  /// `home` | `draw` | `away` | null.
  final String? myPrediction;

  bool get hasVotes => total > 0;

  factory FixturePrediction.fromJson(Map<String, dynamic> j) => FixturePrediction(
        total: (j['total'] as num?)?.toInt() ?? 0,
        homePercent: (j['home_percent'] as num?)?.toDouble() ?? 0,
        drawPercent: (j['draw_percent'] as num?)?.toDouble() ?? 0,
        awayPercent: (j['away_percent'] as num?)?.toDouble() ?? 0,
        isOpen: j['is_open'] == true,
        myPrediction: j['my_prediction']?.toString(),
      );
}

/// A fixture row, and the base of the detail payload. Detail additionally
/// populates [prediction] (and inline events/lineups/statistics, modelled in a
/// later 2A/2B step). List rows leave [prediction] null.
@immutable
class Fixture {
  const Fixture({
    required this.id,
    required this.league,
    required this.status,
    this.datetime,
    this.venue = const Venue(),
    required this.home,
    required this.away,
    this.score = const FixtureScore(),
    this.isFeatured = false,
    this.has = const FixtureHas(),
    this.social = const FixtureSocial(),
    this.prediction,
  });

  final int id;
  final FixtureLeagueRef league;
  final FixtureStatus status;
  final DateTime? datetime;
  final Venue venue;
  final FixtureTeam home;
  final FixtureTeam away;
  final FixtureScore score;
  final bool isFeatured;
  final FixtureHas has;
  final FixtureSocial social;
  final FixturePrediction? prediction;

  factory Fixture.fromJson(Map<String, dynamic> j) => Fixture(
        id: (j['id'] as num).toInt(),
        league: FixtureLeagueRef.fromJson((j['league'] as Map).cast<String, dynamic>()),
        status: FixtureStatus.fromJson((j['status'] as Map).cast<String, dynamic>()),
        datetime: DateFmt.tryParse(j['datetime'] as String?),
        venue: Venue.fromJson((j['venue'] as Map?)?.cast<String, dynamic>()),
        home: FixtureTeam.fromJson((j['home'] as Map).cast<String, dynamic>()),
        away: FixtureTeam.fromJson((j['away'] as Map).cast<String, dynamic>()),
        score: FixtureScore.fromJson((j['score'] as Map?)?.cast<String, dynamic>()),
        isFeatured: j['is_featured'] == true,
        has: FixtureHas.fromJson((j['has'] as Map?)?.cast<String, dynamic>()),
        social: FixtureSocial.fromJson((j['social'] as Map?)?.cast<String, dynamic>()),
        prediction: j['prediction'] is Map
            ? FixturePrediction.fromJson((j['prediction'] as Map).cast<String, dynamic>())
            : null,
      );

  Fixture copyWith({FixtureSocial? social}) => Fixture(
        id: id,
        league: league,
        status: status,
        datetime: datetime,
        venue: venue,
        home: home,
        away: away,
        score: score,
        isFeatured: isFeatured,
        has: has,
        social: social ?? this.social,
        prediction: prediction,
      );
}
