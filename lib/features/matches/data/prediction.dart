import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

import 'comment.dart';

/// A single user's prediction (a scoreline; `outcome` is derived server-side).
/// Carries grading (`is_correct`/`is_exact_score`) once the match is finished,
/// and a `user` when listed in the correct-predictions feed.
@immutable
class PredictionEntry {
  const PredictionEntry({
    required this.id,
    required this.home,
    required this.away,
    this.outcome,
    this.isCorrect,
    this.isExactScore,
    this.likesCount = 0,
    this.likedByMe = false,
    this.createdAt,
    this.user,
  });

  final int id;
  final int home;
  final int away;
  final String? outcome; // home | draw | away
  final bool? isCorrect;
  final bool? isExactScore;
  final int likesCount;
  final bool likedByMe;
  final DateTime? createdAt;
  final CommentUser? user;

  factory PredictionEntry.fromJson(Map<String, dynamic> j) => PredictionEntry(
        id: (j['id'] as num).toInt(),
        home: (j['home'] as num?)?.toInt() ?? 0,
        away: (j['away'] as num?)?.toInt() ?? 0,
        outcome: j['outcome'] as String?,
        isCorrect: j['is_correct'] as bool?,
        isExactScore: j['is_exact_score'] as bool?,
        likesCount: (j['likes_count'] as num?)?.toInt() ?? 0,
        likedByMe: j['liked_by_me'] == true,
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
        user: j['user'] is Map
            ? CommentUser.fromJson((j['user'] as Map).cast<String, dynamic>())
            : null,
      );

  PredictionEntry copyWith({int? likesCount, bool? likedByMe}) =>
      PredictionEntry(
        id: id,
        home: home,
        away: away,
        outcome: outcome,
        isCorrect: isCorrect,
        isExactScore: isExactScore,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
        createdAt: createdAt,
        user: user,
      );
}

/// `GET /fixtures/:id/predictions/summary` — vote shares + counts + the caller's
/// own prediction. `is_open` only while the fixture is scheduled.
@immutable
class PredictionSummary {
  const PredictionSummary({
    this.total = 0,
    this.homePercent = 0,
    this.drawPercent = 0,
    this.awayPercent = 0,
    this.countsHome = 0,
    this.countsDraw = 0,
    this.countsAway = 0,
    this.isOpen = false,
    this.myPrediction,
  });

  final int total;
  final double homePercent;
  final double drawPercent;
  final double awayPercent;
  final int countsHome;
  final int countsDraw;
  final int countsAway;
  final bool isOpen;
  final PredictionEntry? myPrediction;

  bool get hasVotes => total > 0;

  factory PredictionSummary.fromJson(Map<String, dynamic> j) {
    final counts = (j['counts'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PredictionSummary(
      total: (j['total'] as num?)?.toInt() ?? 0,
      homePercent: (j['home_percent'] as num?)?.toDouble() ?? 0,
      drawPercent: (j['draw_percent'] as num?)?.toDouble() ?? 0,
      awayPercent: (j['away_percent'] as num?)?.toDouble() ?? 0,
      countsHome: (counts['home'] as num?)?.toInt() ?? 0,
      countsDraw: (counts['draw'] as num?)?.toInt() ?? 0,
      countsAway: (counts['away'] as num?)?.toInt() ?? 0,
      isOpen: j['is_open'] == true,
      myPrediction: j['my_prediction'] is Map
          ? PredictionEntry.fromJson(
              (j['my_prediction'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}
