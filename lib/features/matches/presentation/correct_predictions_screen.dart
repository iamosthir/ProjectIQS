import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/prediction.dart';
import 'package:iqs_flutter/features/matches/presentation/match_widgets.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';

/// Correct predictions (`/fixtures/:id/predictions/correct`) — users who
/// predicted the right outcome, with a per-row like. Empty before the match
/// is graded.
class CorrectPredictionsScreen extends ConsumerWidget {
  const CorrectPredictionsScreen({super.key, required this.fixtureId});

  final int fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: DetailHeaderRow(title: context.l10n.matchSocialCorrectPredictionsTitle),
          ),
          Expanded(
            child: PaginatedListView<PredictionEntry>(
              loader: (page) => ref
                  .read(matchesRepositoryProvider)
                  .correctPredictions(fixtureId, page: page),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              emptyTitle: context.l10n.matchSocialNoCorrectPredictions,
              itemBuilder: (context, entry, _) =>
                  _PredictionRow(entry: entry),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionRow extends ConsumerStatefulWidget {
  const _PredictionRow({required this.entry});
  final PredictionEntry entry;

  @override
  ConsumerState<_PredictionRow> createState() => _PredictionRowState();
}

class _PredictionRowState extends ConsumerState<_PredictionRow> {
  late bool _liked = widget.entry.likedByMe;
  late int _likes = widget.entry.likesCount;
  bool _liking = false;

  @override
  void didUpdateWidget(_PredictionRow old) {
    super.didUpdateWidget(old);
    final e = widget.entry;
    if (old.entry.id != e.id) {
      _liked = e.likedByMe;
      _likes = e.likesCount;
    } else if (!_liking &&
        (old.entry.likedByMe != e.likedByMe ||
            old.entry.likesCount != e.likesCount)) {
      _liked = e.likedByMe;
      _likes = e.likesCount;
    }
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    final prevLiked = _liked;
    final prevLikes = _likes;
    setState(() {
      _liking = true;
      _liked = !prevLiked;
      _likes = (prevLikes + (_liked ? 1 : -1)).clamp(0, 1 << 30);
    });
    try {
      final repo = ref.read(matchesRepositoryProvider);
      _liked
          ? await repo.likePrediction(widget.entry.id)
          : await repo.unlikePrediction(widget.entry.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _liked = prevLiked;
        _likes = prevLikes;
      });
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final name = e.user?.name ?? context.l10n.matchSocialUser;
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: Clay.circle(AppColors.avatar),
            alignment: Alignment.center,
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 15,
                    weight: AppText.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${e.home} - ${e.away}',
                        style: AppText.tajawal(
                          size: 14,
                          weight: AppText.extraBold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    if (e.isExactScore == true) ...[
                      const SizedBox(width: 8),
                      _badge(context.l10n.matchSocialExactScore),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleLike,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: _liked ? AppColors.logoutText : AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text('$_likes', style: AppText.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppText.tajawal(
          size: 11,
          weight: AppText.bold,
          color: AppColors.pillText,
        ),
      ),
    );
  }
}
