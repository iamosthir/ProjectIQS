import 'package:flutter/foundation.dart';

/// A player reference inside a fixture event (scorer / assist / booked player).
@immutable
class EventPlayerRef {
  const EventPlayerRef({this.id, this.name});
  final int? id;
  final String? name;

  bool get hasName => name != null && name!.isNotEmpty;

  factory EventPlayerRef.fromJson(Map<String, dynamic>? j) => j == null
      ? const EventPlayerRef()
      : EventPlayerRef(id: (j['id'] as num?)?.toInt(), name: j['name'] as String?);
}

/// A timeline event (`GET /fixtures/:id/events`). `type` ∈ goal | card | subst |
/// var | kickoff | half_end | penalty | match_end | match_cancelled |
/// match_postponed. `detail` disambiguates (e.g. "Yellow Card", "Normal Goal").
@immutable
class FixtureEvent {
  const FixtureEvent({
    required this.id,
    this.teamId,
    this.player = const EventPlayerRef(),
    this.assist = const EventPlayerRef(),
    this.elapsed,
    this.extra,
    this.type,
    this.detail,
    this.comments,
  });

  final int id;
  final int? teamId;
  final EventPlayerRef player;
  final EventPlayerRef assist;
  final int? elapsed;
  final int? extra;
  final String? type;
  final String? detail;
  final String? comments;

  bool get isGoal => type == 'goal' || type == 'penalty';
  bool get isCard => type == 'card';
  bool get isSubst => type == 'subst';

  /// True for a red / second-yellow / sending-off card (drives the card color).
  bool get isRedCard {
    final d = (detail ?? '').toLowerCase();
    return isCard &&
        (d.contains('red') ||
            d.contains('second yellow') ||
            d.contains('أحمر') ||
            d.contains('طرد') ||
            d.contains('ثاني'));
  }

  /// `45+2'` style minute label.
  String get minuteLabel {
    if (elapsed == null) return '';
    return (extra != null && extra! > 0) ? "$elapsed+$extra'" : "$elapsed'";
  }

  factory FixtureEvent.fromJson(Map<String, dynamic> j) => FixtureEvent(
        id: (j['id'] as num?)?.toInt() ?? 0,
        teamId: (j['team_id'] as num?)?.toInt(),
        player:
            EventPlayerRef.fromJson((j['player'] as Map?)?.cast<String, dynamic>()),
        assist:
            EventPlayerRef.fromJson((j['assist'] as Map?)?.cast<String, dynamic>()),
        elapsed: (j['elapsed'] as num?)?.toInt(),
        extra: (j['extra'] as num?)?.toInt(),
        type: j['type'] as String?,
        detail: j['detail'] as String?,
        comments: j['comments'] as String?,
      );
}

/// A player row inside a lineup (starter or substitute).
@immutable
class LineupPlayer {
  const LineupPlayer({
    this.id,
    this.name,
    this.number,
    this.position,
    this.grid,
  });
  final int? id;
  final String? name;
  final int? number;
  final String? position;
  final String? grid;

  factory LineupPlayer.fromJson(Map<String, dynamic> j) => LineupPlayer(
        id: (j['id'] as num?)?.toInt(),
        name: j['name'] as String?,
        number: (j['number'] as num?)?.toInt(),
        position: j['position'] as String?,
        grid: j['grid'] as String?,
      );
}

/// One team's lineup (`GET /fixtures/:id/lineups` returns one per team).
@immutable
class Lineup {
  const Lineup({
    this.teamId,
    required this.teamName,
    this.teamLogo,
    this.formation,
    this.coachName,
    this.coachPhoto,
    this.startXI = const [],
    this.substitutes = const [],
  });

  final int? teamId;
  final String teamName;
  final String? teamLogo;
  final String? formation;
  final String? coachName;
  final String? coachPhoto;
  final List<LineupPlayer> startXI;
  final List<LineupPlayer> substitutes;

  static List<LineupPlayer> _players(dynamic raw) => (raw is List)
      ? raw
          .map((e) => LineupPlayer.fromJson((e as Map).cast<String, dynamic>()))
          .toList()
      : const [];

  factory Lineup.fromJson(Map<String, dynamic> j) {
    final team = (j['team'] as Map?)?.cast<String, dynamic>() ?? const {};
    final coach = (j['coach'] as Map?)?.cast<String, dynamic>();
    return Lineup(
      teamId: (team['id'] as num?)?.toInt(),
      teamName: team['name']?.toString() ?? '',
      teamLogo: team['logo'] as String?,
      formation: j['formation'] as String?,
      coachName: coach?['name'] as String?,
      coachPhoto: coach?['photo'] as String?,
      startXI: _players(j['startxi']),
      substitutes: _players(j['substitutes']),
    );
  }
}

/// One team's value for one statistic type (`GET /fixtures/:id/statistics`).
/// The screen pairs home/away rows by [type] into comparison bars.
@immutable
class MatchStatistic {
  const MatchStatistic({
    this.teamId,
    required this.type,
    this.value,
    this.valueNumeric,
  });
  final int? teamId;
  final String type;
  final String? value;
  final double? valueNumeric;

  factory MatchStatistic.fromJson(Map<String, dynamic> j) => MatchStatistic(
        teamId: (j['team_id'] as num?)?.toInt(),
        type: j['type']?.toString() ?? '',
        value: j['value']?.toString(),
        valueNumeric: (j['value_numeric'] as num?)?.toDouble(),
      );
}
