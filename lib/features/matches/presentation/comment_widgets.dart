import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/comment.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// A single comment / reply with optimistic like, owner edit+delete, and a
/// reply-count link (hidden in the replies thread via [isReply]).
class CommentTile extends ConsumerStatefulWidget {
  const CommentTile({
    super.key,
    required this.fixtureId,
    required this.comment,
    required this.onChanged,
    this.isReply = false,
  });

  final int fixtureId;
  final Comment comment;

  /// Called after edit/delete so the parent list reloads.
  final VoidCallback onChanged;
  final bool isReply;

  @override
  ConsumerState<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<CommentTile> {
  late bool _liked = widget.comment.likedByMe;
  late int _likes = widget.comment.likesCount;
  bool _liking = false;

  @override
  void didUpdateWidget(CommentTile old) {
    super.didUpdateWidget(old);
    final c = widget.comment;
    // Resync optimistic like state when the row's id changes, or when a refresh
    // brings new server like state for the same id (but never mid-flight).
    if (old.comment.id != c.id) {
      _liked = c.likedByMe;
      _likes = c.likesCount;
    } else if (!_liking &&
        (old.comment.likedByMe != c.likedByMe ||
            old.comment.likesCount != c.likesCount)) {
      _liked = c.likedByMe;
      _likes = c.likesCount;
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
          ? await repo.likeComment(widget.comment.id)
          : await repo.unlikeComment(widget.comment.id);
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

  Future<void> _edit() async {
    final controller = TextEditingController(text: widget.comment.body);
    final String? newBody;
    try {
      newBody = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.screenBgWhite,
          title: Text(context.l10n.matchSocialEditComment, style: AppText.sectionHeader),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            maxLength: 2000,
            style: AppText.tajawal(size: 15, weight: AppText.medium),
            cursorColor: AppColors.primaryGreen,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel, style: AppText.muted),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(context.l10n.save,
                  style: AppText.tajawal(
                      size: 14,
                      weight: AppText.bold,
                      color: AppColors.primaryGreen)),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (newBody == null || newBody.isEmpty || newBody == widget.comment.body) {
      return;
    }
    try {
      await ref.read(matchesRepositoryProvider).editComment(widget.comment.id, newBody);
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.screenBgWhite,
        title: Text(context.l10n.matchSocialDeleteComment, style: AppText.sectionHeader),
        content: Text(context.l10n.matchSocialDeleteCommentConfirm, style: AppText.muted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: AppText.muted),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.delete,
                style: AppText.tajawal(
                    size: 14,
                    weight: AppText.bold,
                    color: AppColors.logoutText)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(matchesRepositoryProvider).deleteComment(widget.comment.id);
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final isOwner = ref.watch(currentUserProvider)?.id == c.user.id;
    final avatar = assetUrl(c.user.avatar);
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: Clay.circle(AppColors.avatar),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: avatar == null
                ? const Icon(Icons.person, color: Colors.white, size: 22)
                : NetworkImageBox(url: avatar, width: 42, height: 42),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.tajawal(
                          size: 14,
                          weight: AppText.extraBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(DateFmt.relative(c.createdAt), style: AppText.muted),
                    if (isOwner)
                      SizedBox(
                        height: 22,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz,
                              size: 20, color: AppColors.textMuted),
                          onSelected: (v) => v == 'edit' ? _edit() : _delete(),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'edit',
                                child: Text(context.l10n.edit, style: AppText.rowLabel)),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(context.l10n.delete,
                                  style: AppText.tajawal(
                                      size: 15,
                                      weight: AppText.bold,
                                      color: AppColors.logoutText)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  c.body,
                  style: AppText.tajawal(
                    size: 15,
                    weight: AppText.medium,
                    color: AppColors.textSubtleGreen,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: _liked
                                ? AppColors.logoutText
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text('$_likes', style: AppText.muted),
                        ],
                      ),
                    ),
                    if (!widget.isReply) ...[
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => context.push(
                          '/comments/${c.id}/replies',
                          extra: (widget.fixtureId, c.context),
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            const Icon(Icons.reply_rounded,
                                size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              c.repliesCount > 0
                                  ? context.l10n.matchSocialRepliesCount(c.repliesCount)
                                  : context.l10n.matchSocialReply,
                              style: AppText.muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom composer bar: a clay text field + send button. Clears on submit.
class CommentComposer extends StatefulWidget {
  const CommentComposer({
    super.key,
    required this.onSubmit,
    required this.hint,
  });

  /// Returns true on success (the composer clears) or false on failure (the
  /// typed text is kept; the caller surfaces the error).
  final Future<bool> Function(String body) onSubmit;
  final String hint;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final ok = await widget.onSubmit(body);
      // Only clear the field when the post actually succeeded — otherwise keep
      // the user's text so they can retry.
      if (mounted && ok) {
        _controller.clear();
        FocusScope.of(context).unfocus();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A1C5030),
            blurRadius: 20,
            offset: Offset(0, -6),
            spreadRadius: -8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: Clay.card(radius: 18, gradient: AppColors.surface),
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    textInputAction: TextInputAction.newline,
                    style: AppText.tajawal(size: 15, weight: AppText.medium),
                    cursorColor: AppColors.primaryGreen,
                    inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      counterText: '',
                      hintText: widget.hint,
                      hintStyle: AppText.muted,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: Clay.circle(AppColors.primary),
                  alignment: Alignment.center,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
