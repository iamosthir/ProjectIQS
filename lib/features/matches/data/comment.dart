import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// Author reference embedded in comments and prediction rows.
@immutable
class CommentUser {
  const CommentUser({required this.id, required this.name, this.avatar});
  final int id;
  final String name;
  final String? avatar;

  factory CommentUser.fromJson(Map<String, dynamic> j) => CommentUser(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        avatar: j['avatar'] as String?,
      );
}

/// A match comment or reply (`parent_id` set for replies). `context` is
/// `match` | `prediction`. Body ≤ 2000 chars (server-enforced).
@immutable
class Comment {
  const Comment({
    required this.id,
    required this.body,
    this.context = 'match',
    this.parentId,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.isHidden = false,
    this.likedByMe = false,
    required this.user,
    this.createdAt,
  });

  final int id;
  final String body;
  final String context;
  final int? parentId;
  final int likesCount;
  final int repliesCount;
  final bool isHidden;
  final bool likedByMe;
  final CommentUser user;
  final DateTime? createdAt;

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: (j['id'] as num).toInt(),
        body: j['body']?.toString() ?? '',
        context: j['context']?.toString() ?? 'match',
        parentId: (j['parent_id'] as num?)?.toInt(),
        likesCount: (j['likes_count'] as num?)?.toInt() ?? 0,
        repliesCount: (j['replies_count'] as num?)?.toInt() ?? 0,
        isHidden: j['is_hidden'] == true,
        likedByMe: j['liked_by_me'] == true,
        user: CommentUser.fromJson(
            (j['user'] as Map?)?.cast<String, dynamic>() ?? const {}),
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
      );

  Comment copyWith({
    String? body,
    int? likesCount,
    bool? likedByMe,
    int? repliesCount,
  }) =>
      Comment(
        id: id,
        body: body ?? this.body,
        context: context,
        parentId: parentId,
        likesCount: likesCount ?? this.likesCount,
        repliesCount: repliesCount ?? this.repliesCount,
        isHidden: isHidden,
        likedByMe: likedByMe ?? this.likedByMe,
        user: user,
        createdAt: createdAt,
      );
}
