import 'package:flutter/foundation.dart';

import 'team.dart';

/// A league standings row (`GET /leagues/:id/standings`). `group` is non-null
/// only for grouped competitions — render group headers when present.
@immutable
class Standing {
  const Standing({
    required this.rank,
    required this.team,
    this.group,
    this.points = 0,
    this.goalsDiff = 0,
    this.played = 0,
    this.win = 0,
    this.draw = 0,
    this.lose = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.form,
  });

  final int rank;
  final TeamRef team;
  final String? group;
  final int points;
  final int goalsDiff;
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsFor;
  final int goalsAgainst;
  final String? form;

  factory Standing.fromJson(Map<String, dynamic> j) => Standing(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        team: TeamRef.fromJson((j['team'] as Map).cast<String, dynamic>()),
        group: j['group'] as String?,
        points: (j['points'] as num?)?.toInt() ?? 0,
        goalsDiff: (j['goals_diff'] as num?)?.toInt() ?? 0,
        played: (j['played'] as num?)?.toInt() ?? 0,
        win: (j['win'] as num?)?.toInt() ?? 0,
        draw: (j['draw'] as num?)?.toInt() ?? 0,
        lose: (j['lose'] as num?)?.toInt() ?? 0,
        goalsFor: (j['goals_for'] as num?)?.toInt() ?? 0,
        goalsAgainst: (j['goals_against'] as num?)?.toInt() ?? 0,
        form: j['form'] as String?,
      );
}

/// A top-scorer row (`GET /leagues/:id/top-scorers`). Seed data is empty, so the
/// shape is parsed defensively.
@immutable
class TopScorer {
  const TopScorer({
    this.rank,
    required this.playerId,
    required this.playerName,
    this.playerPhoto,
    this.team,
    this.goals = 0,
    this.assists,
  });

  final int? rank;
  final int playerId;
  final String playerName;
  final String? playerPhoto;
  final TeamRef? team;
  final int goals;
  final int? assists;

  factory TopScorer.fromJson(Map<String, dynamic> j) {
    final player = j['player'];
    return TopScorer(
      rank: (j['rank'] as num?)?.toInt(),
      playerId: player is Map ? (player['id'] as num?)?.toInt() ?? 0 : 0,
      playerName: player is Map
          ? (player['name']?.toString() ?? '')
          : (j['name']?.toString() ?? ''),
      playerPhoto: player is Map ? player['photo'] as String? : null,
      team: j['team'] is Map
          ? TeamRef.fromJson((j['team'] as Map).cast<String, dynamic>())
          : null,
      goals: (j['goals'] as num?)?.toInt() ?? 0,
      assists: (j['assists'] as num?)?.toInt(),
    );
  }
}
