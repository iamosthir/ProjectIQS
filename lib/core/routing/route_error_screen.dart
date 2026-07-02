import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';

/// Shown by the router's `errorBuilder` when a location matches no route (e.g.
/// a deep link to a not-yet-shipped feature). Styled with the clay kit instead
/// of go_router's raw error page.
class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Center(
                child: Text(context.l10n.discoveryErrorTitle,
                    style: AppText.screenTitle)),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore_off_rounded,
                        size: 56,
                        color: AppColors.textMuted.withValues(alpha: 0.6)),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.discoveryPageNotAvailableTitle,
                      style: AppText.tajawal(
                        size: 18,
                        weight: AppText.extraBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.discoveryPageNotAvailableBody,
                      textAlign: TextAlign.center,
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 20),
                    GreenPillButton(
                      label: context.l10n.discoveryBackToHome,
                      onTap: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
