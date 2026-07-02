import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/comment.dart';
import 'package:iqs_flutter/features/matches/presentation/match_widgets.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'comment_widgets.dart';

/// Replies thread (`/comments/:id/replies`), oldest-first. `fixtureId` is passed
/// via go_router `extra` so a reply can be posted (`parent_id` = this comment).
class RepliesScreen extends ConsumerStatefulWidget {
  const RepliesScreen({
    super.key,
    required this.commentId,
    this.fixtureId,
    this.parentContext = 'match',
  });

  final int commentId;
  final int? fixtureId;

  /// The parent comment's context (`match`|`prediction`) so a reply is filed
  /// under the same context as its parent.
  final String parentContext;

  @override
  ConsumerState<RepliesScreen> createState() => _RepliesScreenState();
}

class _RepliesScreenState extends ConsumerState<RepliesScreen> {
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: DetailHeaderRow(title: context.l10n.matchSocialRepliesTitle),
          ),
          Expanded(
            child: PaginatedListView<Comment>(
              key: ValueKey(_reload),
              loader: (page) => ref
                  .read(matchesRepositoryProvider)
                  .replies(widget.commentId, page: page),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              emptyTitle: context.l10n.matchSocialNoReplies,
              emptySubtitle: widget.fixtureId == null ? null : context.l10n.matchSocialBeFirstToReply,
              itemBuilder: (context, reply, _) => CommentTile(
                fixtureId: widget.fixtureId ?? 0,
                comment: reply,
                onChanged: _refresh,
                isReply: true,
              ),
            ),
          ),
          if (widget.fixtureId != null)
            CommentComposer(
              hint: context.l10n.matchSocialAddReplyHint,
              onSubmit: (body) => _postReply(body),
            ),
        ],
      ),
    );
  }

  Future<bool> _postReply(String body) async {
    final fixtureId = widget.fixtureId;
    if (fixtureId == null) return false;
    try {
      await ref.read(matchesRepositoryProvider).postComment(
            fixtureId,
            body: body,
            context: widget.parentContext,
            parentId: widget.commentId,
          );
      if (mounted) _refresh();
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
      return false;
    }
  }
}
