import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/clubs/application/clubs_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// Club news article (`/clubs/:id/news/:newsId`). Increments views server-side.
class ClubNewsArticleScreen extends ConsumerWidget {
  const ClubNewsArticleScreen({
    super.key,
    required this.clubId,
    required this.newsId,
  });

  final int clubId;
  final int newsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (clubId: clubId, newsId: newsId);
    final async = ref.watch(clubNewsArticleProvider(key));
    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
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
                      child: Text(context.l10n.clubsNewsTitle,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/clubs/$clubId'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(clubNewsArticleProvider(key)),
              data: (news) {
                final cover = assetUrl(news.cover);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cover != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: SizedBox(
                            height: 210,
                            width: double.infinity,
                            child: NetworkImageBox(url: cover, fit: BoxFit.cover),
                          ),
                        ),
                      if (cover != null) const SizedBox(height: 18),
                      Text(
                        news.title,
                        style: AppText.tajawal(
                          size: 22,
                          weight: AppText.extraBold,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          if (news.authorName != null)
                            _meta(Icons.person_outline, news.authorName!),
                          if (news.publishedAt != null)
                            _meta(Icons.schedule,
                                DateFmt.relative(news.publishedAt)),
                          _meta(Icons.visibility_outlined,
                              context.l10n.clubsViewsCount(news.viewsCount)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        (news.content?.isNotEmpty ?? false)
                            ? news.content!
                            : (news.excerpt ?? ''),
                        style: AppText.tajawal(
                          size: 16,
                          weight: AppText.regular,
                          color: AppColors.textSubtleGreen,
                          height: 1.9,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: AppText.muted),
      ],
    );
  }
}
