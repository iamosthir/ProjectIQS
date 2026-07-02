import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/pressable.dart';

/// Centered loading spinner in the brand green. Every `AsyncValue` loading
/// branch renders this.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryGreen,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!, style: AppText.muted, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Generic error placeholder with an optional retry. Use [appErrorView] to pick
/// this vs [OfflineState] automatically from an [ApiException].
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: icon,
      title: context.l10n.errorTitle,
      subtitle: message ?? context.l10n.errorUnexpected,
      onRetry: onRetry,
    );
  }
}

/// No-connectivity variant. Shown when the failure is an [ApiException] of kind
/// network (timeout / connection error).
class OfflineState extends StatelessWidget {
  const OfflineState({super.key, this.onRetry, this.message});

  final VoidCallback? onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: Icons.wifi_off_rounded,
      title: context.l10n.noConnectionTitle,
      subtitle: message ?? context.l10n.noConnectionBody,
      onRetry: onRetry,
    );
  }
}

/// Empty-list placeholder.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.onRetry,
  });

  final String? title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(
      icon: icon,
      title: title ?? context.l10n.noData,
      subtitle: subtitle,
      onRetry: onRetry,
      retryLabel: context.l10n.refresh,
    );
  }
}

/// Resolves an arbitrary error into the right placeholder (offline vs generic).
Widget appErrorView(Object error, {VoidCallback? onRetry}) {
  if (error is ApiException && error.isNetwork) {
    // Network failures render the localized offline copy, not the raw
    // (transport-fallback) message.
    return OfflineState(onRetry: onRetry);
  }
  // Server failures carry a backend-localized message; anything else falls back
  // to the localized "unexpected error" resolved inside ErrorState.
  final message = error is ApiException ? error.message : null;
  return ErrorState(message: message, onRetry: onRetry);
}

/// Convenience wrapper around [AsyncValue.when] that renders the standard
/// loading/error/offline placeholders, so screens only supply [data].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const LoadingState(),
      error: (err, _) => appErrorView(err, onRetry: onRetry),
    );
  }
}

/// Shared internal layout for the error/empty/offline placeholders.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                size: 18,
                weight: AppText.extraBold,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: AppText.muted),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GreenPillButton(
                  label: retryLabel ?? context.l10n.retry, onTap: onRetry!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small green gradient pill button matching the app's inline action buttons
/// (e.g. the More-screen "تعديل"). Reused by the state placeholders and forms.
class GreenPillButton extends StatelessWidget {
  const GreenPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 22),
          decoration: BoxDecoration(
            gradient: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.green1D8040.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 8),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(
                label,
                style: AppText.tajawal(
                  size: 14,
                  weight: AppText.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
