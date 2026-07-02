import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/shared/data/reference_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';

/// Startup gate (`/`). Restores the session and evaluates the version gate; the
/// router's redirect moves on once `authProvider`/`appConfigProvider` resolve.
/// Shows a retry only if session restore fails with a transport error.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    // Kick off the config fetch so the force-update gate can be evaluated.
    ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
      body: Center(
        child: auth.hasError
            ? Padding(
                padding: const EdgeInsets.all(28),
                child: appErrorView(
                  auth.error!,
                  onRetry: () => ref.invalidate(authProvider),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 200,
                    height: 104,
                    alignment: Alignment.center,
                    child: Image.asset('assets/iqs-logo.jpeg',
                        width: 156, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(context.l10n.loadingLabel, style: AppText.muted),
                ],
              ),
      ),
    );
  }
}
