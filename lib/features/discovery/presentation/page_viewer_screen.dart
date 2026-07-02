import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/shared/data/reference_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Static legal/info page viewer (`/page/:slug`). Reachable pre-login and from
/// Settings. Renders `GET /pages/:slug` (privacy/terms/about).
class PageViewerScreen extends ConsumerWidget {
  const PageViewerScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pageProvider(slug));
    final title = async.valueOrNull?.title ?? context.l10n.discoveryPageFallbackTitle;

    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.screenTitle,
                    ),
                  ),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(pageProvider(slug)),
              data: (page) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      style: AppText.tajawal(
                        size: 22,
                        weight: AppText.extraBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.content,
                      style: AppText.tajawal(
                        size: 15,
                        weight: AppText.regular,
                        color: AppColors.textSubtleGreen,
                        height: 1.8,
                      ),
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
