import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/store.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// My Store (`/market/my-store`) — create CTA when the user has no store, else
/// the seller dashboard (store card + entry points).
class MyStoreScreen extends ConsumerWidget {
  const MyStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myStoreProvider);
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
                      child:
                          Text(context.l10n.sellerMyStoreTitle, style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/market'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myStoreProvider),
              data: (store) =>
                  store == null ? _createCta(context) : _dashboard(context, store),
            ),
          ),
        ],
      ),
    );
  }

  Widget _createCta(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 72, color: AppColors.primaryGreen),
            const SizedBox(height: 20),
            Text(
              context.l10n.sellerCreateStoreHeadline,
              style: AppText.tajawal(
                size: 22,
                weight: AppText.extraBold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.sellerCreateStoreBody,
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                size: 14,
                weight: AppText.medium,
                color: AppColors.sectionLabel,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 220,
              child: Clay3DButton(
                label: context.l10n.sellerCreateStoreButton,
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
                height: 58,
                radius: 18,
                onTap: () => context.push('/market/store/edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context, Store store) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClayCard(
            strong: true,
            radius: 24,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: Clay.circle(AppColors.avatar),
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.tajawal(
                                size: 18,
                                weight: AppText.extraBold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (store.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified,
                                size: 18, color: AppColors.primaryGreen),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(context.l10n.sellerListingsCount(store.listingsCount),
                          style: AppText.muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _tile(context, Icons.list_alt_rounded, context.l10n.sellerMyListings,
              '/market/my-listings'),
          const SizedBox(height: 12),
          _tile(context, Icons.add_circle_outline, context.l10n.sellerAddListing,
              '/market/listings/new'),
          const SizedBox(height: 12),
          _tile(context, Icons.edit_outlined, context.l10n.sellerEditStore,
              '/market/store/edit'),
        ],
      ),
    );
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
