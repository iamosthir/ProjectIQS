import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/routing/deep_link.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/notifications/application/notifications_providers.dart';
import 'package:iqs_flutter/features/notifications/data/app_notification.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Notifications inbox (`/notifications`). Newest-first, unread highlight,
/// pull-to-refresh, mark-all-read. Tap → mark read + deep-link.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _reload = 0;

  @override
  void initState() {
    super.initState();
    // Reconcile the badge with the server every time the inbox opens (covers
    // notifications created mid-session while push is dormant/unconfigured).
    // Post-frame so we don't invalidate a provider the bells are watching
    // mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(unreadCountProvider);
    });
  }

  void _refresh() {
    if (mounted) setState(() => _reload++);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _markAll() async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      _refresh();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      // Fire-and-forget mark-read; failure shouldn't block navigation.
      ref
          .read(notificationsRepositoryProvider)
          .markRead(n.id)
          .then((_) => ref.invalidate(unreadCountProvider))
          .catchError((_) {});
    }
    final link = n.deepLink;
    if (link.isActionable) {
      await handleDeepLink(context, link);
      // Reload after returning from the detail route (reflects the read state).
      _refresh();
    } else {
      // Non-actionable tap: reconcile the badge only — no full list reload /
      // scroll-to-top for a notification that doesn't navigate anywhere.
      ref.invalidate(unreadCountProvider);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                ClayHeaderButton(
                  icon: Icons.done_all,
                  iconSize: 22,
                  onTap: _markAll,
                ),
                Expanded(
                  child: Center(
                      child: Text(context.l10n.notifTitle,
                      style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedListView<AppNotification>(
              key: ValueKey('notifications-$_reload'),
              loader: (page) =>
                  ref.read(notificationsRepositoryProvider).list(page: page),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              emptyTitle: context.l10n.notifEmpty,
              itemBuilder: (context, n, _) =>
                  _NotificationRow(notification: n, onTap: () => _open(n)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.isRead;
    return ClayCard(
      radius: 18,
      strong: unread,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: Clay.settingsTile(),
            child: Icon(notificationIcon(n.type),
                size: 22, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tajawal(
                              size: 15,
                              weight: unread ? AppText.extraBold : AppText.bold,
                              color: AppColors.textPrimary,
                              height: 1.35)),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(n.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tajawal(
                          size: 13,
                          weight: AppText.regular,
                          color: AppColors.textSubtleGreen,
                          height: 1.55)),
                ],
                if (n.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(DateFmt.relative(n.createdAt!), style: AppText.muted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
