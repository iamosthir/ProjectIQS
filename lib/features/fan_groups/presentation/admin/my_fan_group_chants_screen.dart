import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'admin_archive_widgets.dart';

/// Chants manager (`/my-fan-group/chants`). List + delete. Limit 20.
/// (Adding a chant needs a web video upload.)
class MyFanGroupChantsScreen extends ConsumerWidget {
  const MyFanGroupChantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFanGroupChantsProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(
                  child: Center(
                      child: Text(context.l10n.fanAdminManageChants,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/my-fan-group'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myFanGroupChantsProvider),
              data: (chants) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  archiveAddNote(context.l10n.fanAdminChantsAddNote),
                  if (chants.isEmpty)
                    SizedBox(
                        height: 220,
                        child: EmptyState(
                            title: context.l10n.fanAdminNoChants))
                  else
                    for (final c in chants) ...[
                      _ChantRow(
                          chant: c, onDelete: () => _delete(context, ref, c)),
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

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FanGroupChant c) async {
    if (!await confirmArchiveDelete(context, c.title)) return;
    try {
      await ref.read(fanGroupsRepositoryProvider).deleteChant(c.id);
      if (!context.mounted) return;
      ref.invalidate(myFanGroupChantsProvider);
      ref.invalidate(myFanGroupProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _ChantRow extends StatelessWidget {
  const _ChantRow({required this.chant, required this.onDelete});
  final FanGroupChant chant;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final thumb = assetUrl(chant.thumbnail);
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
            child: Text(chant.title,
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
