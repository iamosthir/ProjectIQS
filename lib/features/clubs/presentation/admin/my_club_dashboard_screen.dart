import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/clubs/application/clubs_providers.dart';
import 'package:iqs_flutter/features/clubs/data/club_detail.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'club_admin_specs.dart';

/// My Club dashboard (`/my-club`). 403 → not a club-admin (hide). Else: the
/// managed club + entry points to edit profile, news, and content managers.
class MyClubDashboardScreen extends ConsumerWidget {
  const MyClubDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClubProvider);
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
                      child: Text(context.l10n.clubAdminDashboardTitle,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/news'),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingState(),
              error: (e, _) =>
                  (e is ApiException && e.isForbidden) ? _notAdmin(context) : appErrorView(
                      e, onRetry: () => ref.invalidate(myClubProvider)),
              data: (club) => _dashboard(context, club),
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
            Text(context.l10n.clubAdminNotAdminTitle,
                style: AppText.tajawal(
                    size: 18,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(context.l10n.clubAdminNotAdminBody,
                textAlign: TextAlign.center, style: AppText.muted),
          ],
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context, ClubDetail club) {
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
                child: const Icon(Icons.shield, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(club.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tajawal(
                              size: 18,
                              weight: AppText.extraBold,
                              color: AppColors.textPrimary)),
                    ),
                    if (club.isVerified) ...[
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
        _tile(context, Icons.edit_outlined, context.l10n.clubAdminEditClubData,
            '/my-club/edit'),
        const SizedBox(height: 12),
        _tile(context, Icons.article_outlined, context.l10n.clubAdminManageNews,
            '/my-club/news'),
        const SizedBox(height: 12),
        for (final type in const ['board', 'staff', 'titles', 'captains', 'competitions']) ...[
          _tile(context, _icon(type), childTypeLabel(type, context.l10n),
              '/my-club/content/$type'),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'board':
        return Icons.groups_outlined;
      case 'staff':
        return Icons.badge_outlined;
      case 'titles':
        return Icons.emoji_events_outlined;
      case 'captains':
        return Icons.star_outline;
      case 'competitions':
        return Icons.sports_soccer;
      default:
        return Icons.list_alt;
    }
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
