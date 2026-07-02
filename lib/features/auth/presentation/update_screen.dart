import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/shared/data/reference_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';

/// Force/soft update screen (`/update`). Force-update is blocking (no skip);
/// soft-update offers "لاحقاً". Opens the store URL from `app/config.version`.
class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appConfigProvider).valueOrNull?.version;
    final force = version?.forceUpdate ?? false;

    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.system_update_rounded,
                  size: 88, color: AppColors.primaryGreen),
              const SizedBox(height: 24),
              Text(
                force
                    ? context.l10n.authUpdateRequiredTitle
                    : context.l10n.authUpdateAvailableTitle,
                textAlign: TextAlign.center,
                style: AppText.tajawal(
                  size: 24,
                  weight: AppText.extraBold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                version?.changelog ?? context.l10n.authUpdateBody,
                textAlign: TextAlign.center,
                style: AppText.tajawal(
                  size: 15,
                  weight: AppText.medium,
                  color: AppColors.sectionLabel,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              Clay3DButton(
                label: context.l10n.authUpdateNow,
                gradient: AppColors.login3d,
                hardShadow: AppColors.login3dHardShadow,
                softShadow: [
                  BoxShadow(
                    color: const Color(0xFF19773B).withValues(alpha: 0.55),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                    spreadRadius: -6,
                  ),
                ],
                height: 62,
                radius: 20,
                onTap: () => _openStore(context, version?.storeUrl),
              ),
              if (!force) ...[
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        context.l10n.authLater,
                        style: AppText.tajawal(
                          size: 15,
                          weight: AppText.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {/* unlaunchable URL — ignore */}
    }
  }
}
