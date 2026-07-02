import 'dart:async';

import 'package:flutter/material.dart';

import 'package:iqs_flutter/core/routing/deep_link.dart';
import 'package:iqs_flutter/features/notifications/data/app_notification.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';

/// Shows a foreground in-app notification banner (clay top toast). Built once
/// here so FCM foreground messages (Phase 8B) render consistently; tapping it
/// routes via the shared deep-link router. Auto-dismisses after [duration].
void showNotificationBanner(
  BuildContext context, {
  required String title,
  required String body,
  String type = 'general',
  DeepLink? deepLink,
  Duration duration = const Duration(seconds: 5),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  void remove() {
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) => _NotificationBanner(
      title: title,
      body: body,
      type: type,
      duration: duration,
      onTap: () {
        remove();
        if (deepLink != null && deepLink.isActionable) {
          handleDeepLink(ctx, deepLink);
        }
      },
      onDismiss: remove,
    ),
  );
  overlay.insert(entry);
}

class _NotificationBanner extends StatefulWidget {
  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.type,
    required this.duration,
    required this.onTap,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final String type;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) {
      widget.onDismiss();
      return;
    }
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: const ValueKey('notif-banner'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: Clay.card(radius: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: Clay.settingsTile(),
                          child: Icon(notificationIcon(widget.type),
                              size: 22, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.tajawal(
                                      size: 15,
                                      weight: AppText.extraBold,
                                      color: AppColors.textPrimary)),
                              if (widget.body.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(widget.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.tajawal(
                                        size: 13,
                                        weight: AppText.regular,
                                        color: AppColors.textSubtleGreen,
                                        height: 1.4)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
