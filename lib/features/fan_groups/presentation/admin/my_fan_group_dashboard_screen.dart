import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// My Fan Group dashboard (`/my-fan-group`). 403 → not a group-admin (hide).
/// Else: the managed group + entry points to edit profile and the
/// media/chants/documents managers.
class MyFanGroupDashboardScreen extends ConsumerWidget {
  const MyFanGroupDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFanGroupProvider);
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
                      child: Text(context.l10n.fanAdminManageTitle,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/video'),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingState(),
              error: (e, _) => (e is ApiException && e.isForbidden)
                  ? _notAdmin(context)
                  : appErrorView(e,
                      onRetry: () => ref.invalidate(myFanGroupProvider)),
              data: (group) => _dashboard(context, group),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notAdmin(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined,
                size: 64, color: AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(context.l10n.fanAdminNotAdminTitle,
                style: AppText.tajawal(
                    size: 18,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(context.l10n.fanAdminNotAdminBody,
                textAlign: TextAlign.center, style: AppText.muted),
          ],
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context, FanGroupDetail group) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      children: [
        ClayCard(
          strong: true,
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: Clay.circle(AppColors.avatar),
                alignment: Alignment.center,
                child: const Icon(Icons.campaign, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tajawal(
                              size: 18,
                              weight: AppText.extraBold,
                              color: AppColors.textPrimary)),
                    ),
                    if (group.group.isOfficial || group.group.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 18, color: AppColors.primaryGreen),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _tile(context, Icons.edit_outlined, context.l10n.fanAdminEditGroupData,
            '/my-fan-group/edit'),
        const SizedBox(height: 12),
        _tile(context, Icons.photo_library_outlined,
            context.l10n.fanAdminManageMedia, '/my-fan-group/media'),
        const SizedBox(height: 12),
        _tile(context, Icons.music_note_outlined,
            context.l10n.fanAdminManageChants, '/my-fan-group/chants'),
        const SizedBox(height: 12),
        _tile(context, Icons.description_outlined,
            context.l10n.fanAdminManageDocuments, '/my-fan-group/documents'),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String route) {
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: Clay.settingsTile(),
            child: Icon(icon, size: 22, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppText.rowLabel)),
          const Icon(Icons.chevron_left, color: AppColors.chevron, size: 20),
        ],
      ),
    );
  }
}
