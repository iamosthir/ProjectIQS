import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/comment.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'comment_widgets.dart';

/// The self-contained comments feed for a fixture: context toggle (match /
/// prediction), sort, paginated list, like/reply/owner-edit-delete, and a
/// composer. Reused by the standalone comments screen and the match-detail
/// "Fan Zone" tab.
class CommentsFeed extends ConsumerStatefulWidget {
  const CommentsFeed({super.key, required this.fixtureId});

  final int fixtureId;

  @override
  ConsumerState<CommentsFeed> createState() => _CommentsFeedState();
}

class _CommentsFeedState extends ConsumerState<CommentsFeed> {
  String _context = 'match';
  String _sort = 'newest';
  int _reload = 0;

  static Map<String, String> _sorts(AppLocalizations l) => {
    'newest': l.matchSocialSortNewest,
    'oldest': l.matchSocialSortOldest,
    'most_liked': l.matchSocialSortMostLiked,
    'most_replied': l.matchSocialSortMostActive,
  };

  void _refresh() => setState(() => _reload++);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _controlBar(),
        ),
        Expanded(
          child: PaginatedListView<Comment>(
            key: ValueKey('$_context-$_sort-$_reload'),
            loader: (page) => ref.read(matchesRepositoryProvider).comments(
                  widget.fixtureId,
                  context: _context,
                  sort: _sort,
                  page: page,
                ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            emptyTitle: context.l10n.matchSocialNoComments,
            emptySubtitle: context.l10n.matchSocialBeFirstToComment,
            itemBuilder: (context, comment, _) => CommentTile(
              fixtureId: widget.fixtureId,
              comment: comment,
              onChanged: _refresh,
            ),
          ),
        ),
        CommentComposer(hint: context.l10n.matchSocialAddCommentHint, onSubmit: _post),
      ],
    );
  }

  Widget _controlBar() {
    return Row(
      children: [
        Expanded(
          child: AppChip(
            label: context.l10n.matchSocialContextMatch,
            active: _context == 'match',
            onTap: () => setState(() => _context = 'match'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppChip(
            label: context.l10n.matchSocialContextPredictions,
            active: _context == 'prediction',
            onTap: () => setState(() => _context = 'prediction'),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: Clay.headerButton(radius: 14),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 22),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => [
              for (final e in _sorts(context.l10n).entries)
                PopupMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: AppText.tajawal(
                      size: 14,
                      weight: _sort == e.key ? AppText.bold : AppText.medium,
                      color: _sort == e.key
                          ? AppColors.primaryGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _post(String body) async {
    try {
      await ref.read(matchesRepositoryProvider).postComment(
            widget.fixtureId,
            body: body,
            context: _context,
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
