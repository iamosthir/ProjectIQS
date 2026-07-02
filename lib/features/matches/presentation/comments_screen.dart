import 'package:flutter/material.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/features/matches/presentation/match_widgets.dart';
import 'comments_feed.dart';

/// Comments feed (`/fixtures/:id/comments`) — context toggle (match/prediction),
/// sort, post, like, reply, owner edit/delete. Thin wrapper around the shared
/// [CommentsFeed] (also embedded in the match-detail "Fan Zone" tab).
class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key, required this.fixtureId});

  final int fixtureId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: DetailHeaderRow(title: context.l10n.matchSocialCommentsTitle),
          ),
          Expanded(child: CommentsFeed(fixtureId: fixtureId)),
        ],
      ),
    );
  }
}
