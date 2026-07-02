import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/matches/data/fixture_news.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// In-app match-news article. The [news] is handed in via go_router `extra`
/// (the list already carries the full body, so no extra fetch is needed).
class FixtureNewsArticleScreen extends StatelessWidget {
  const FixtureNewsArticleScreen({super.key, this.news});

  final FixtureNews? news;

  @override
  Widget build(BuildContext context) {
    final n = news;
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
                      child: Text(context.l10n.matchSocialNewsTitle, style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop() ? context.pop() : context.go('/matches'),
                ),
              ],
            ),
          ),
          Expanded(
            child: n == null
                ? EmptyState(title: context.l10n.matchSocialNewsUnavailable)
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (assetUrl(n.cover) != null)
                        SizedBox(
                          height: 210,
                          width: double.infinity,
                          child:
                              NetworkImageBox(url: assetUrl(n.cover)!, fit: BoxFit.cover),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: AppText.tajawal(
                                    size: 21,
                                    weight: AppText.extraBold,
                                    color: AppColors.textPrimary,
                                    height: 1.45)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (n.source != null && n.source!.isNotEmpty) ...[
                                  Text(n.source!, style: AppText.muted),
                                  const SizedBox(width: 8),
                                  const Text('·', style: TextStyle(color: AppColors.textMuted)),
                                  const SizedBox(width: 8),
                                ],
                                if (n.publishedAt != null)
                                  Text(DateFmt.relative(n.publishedAt!),
                                      style: AppText.muted),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              n.content?.isNotEmpty == true
                                  ? n.content!
                                  : (n.excerpt ?? ''),
                              style: AppText.tajawal(
                                  size: 15,
                                  weight: AppText.regular,
                                  color: AppColors.textSubtleGreen,
                                  height: 1.9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
