import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'admin_archive_widgets.dart';

/// Media manager (`/my-fan-group/media`). Photos/videos tabs; list + delete.
/// Limits: 100 images / 30 videos. (Adding new media needs a web upload.)
class MyFanGroupMediaScreen extends ConsumerStatefulWidget {
  const MyFanGroupMediaScreen({super.key});

  @override
  ConsumerState<MyFanGroupMediaScreen> createState() =>
      _MyFanGroupMediaScreenState();
}

class _MyFanGroupMediaScreenState extends ConsumerState<MyFanGroupMediaScreen> {
  String _type = 'image';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myFanGroupMediaProvider(_type));
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 50),
                    Expanded(
                      child: Center(
                          child: Text(context.l10n.fanAdminManageMedia,
                              style: AppText.screenTitle)),
                    ),
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/my-fan-group'),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: Clay.headerButton(radius: 16),
                        child: const Icon(Icons.chevron_left,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppChip(
                      label: context.l10n.fanAdminPhotos,
                      active: _type == 'image',
                      onTap: () => setState(() => _type = 'image'),
                    ),
                    const SizedBox(width: 8),
                    AppChip(
                      label: context.l10n.fanAdminVideos,
                      active: _type == 'video',
                      onTap: () => setState(() => _type = 'video'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myFanGroupMediaProvider(_type)),
              data: (items) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  archiveAddNote(context.l10n.fanAdminMediaAddNote),
                  if (items.isEmpty)
                    SizedBox(
                        height: 220,
                        child: EmptyState(
                            title: context.l10n.fanAdminNoMedia))
                  else
                    for (final m in items) ...[
                      _MediaRow(media: m, onDelete: () => _delete(m)),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(FanGroupMedia m) async {
    if (!await confirmArchiveDelete(context, m.title ?? context.l10n.fanAdminItem)) {
      return;
    }
    try {
      await ref.read(fanGroupsRepositoryProvider).deleteMedia(m.id);
      if (!mounted) return;
      ref.invalidate(myFanGroupMediaProvider(_type));
      ref.invalidate(myFanGroupProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.media, required this.onDelete});
  final FanGroupMedia media;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumb = assetUrl(media.thumbnail) ?? assetUrl(media.url);
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 84,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumb == null
                      ? Container(color: AppColors.sliderBg)
                      : NetworkImageBox(url: thumb, fit: BoxFit.cover),
                  if (media.isVideo)
                    const Center(
                      child: Icon(Icons.play_circle_fill,
                          color: Colors.white, size: 26),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                media.title ??
                    (media.isVideo
                        ? context.l10n.fanAdminVideo
                        : context.l10n.fanAdminPhoto),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.tajawal(
                    size: 14,
                    weight: AppText.bold,
                    color: AppColors.textPrimary,
                    height: 1.4)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.logoutText),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
