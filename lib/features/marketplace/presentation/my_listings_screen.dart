import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/listing.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// My Listings (`/market/my-listings`) — all statuses, with edit / media /
/// delete per listing.
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  int _reload = 0;

  void _refresh() => setState(() => _reload++);

  /// Guarded refresh for post-pop callbacks — the pushed route can outlive this
  /// screen (e.g. a 401 redirect replaces the stack).
  void _refreshIfMounted() {
    if (mounted) _refresh();
  }

  Future<void> _delete(Listing l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.screenBgWhite,
        title: Text(context.l10n.sellerDeleteListingTitle, style: AppText.sectionHeader),
        content: Text(context.l10n.sellerDeleteListingConfirm(l.title),
            style: AppText.muted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel, style: AppText.muted),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.delete,
                style: AppText.tajawal(
                    size: 14,
                    weight: AppText.bold,
                    color: AppColors.logoutText)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(marketplaceRepositoryProvider).deleteListing(l.id);
      ref.invalidate(myStoreProvider);
      if (!mounted) return;
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
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
                  icon: Icons.add,
                  onTap: () => context
                      .push('/market/listings/new')
                      .then((_) => _refreshIfMounted()),
                ),
                Expanded(
                  child: Center(
                    child: Text(context.l10n.sellerMyListings, style: AppText.screenTitle),
                  ),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/market/my-store'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedListView<Listing>(
              key: ValueKey(_reload),
              loader: (page) =>
                  ref.read(marketplaceRepositoryProvider).myListings(page: page),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              emptyTitle: context.l10n.sellerNoListings,
              emptySubtitle: context.l10n.sellerNoListingsSubtitle,
              itemBuilder: (context, listing, _) => _MyListingCard(
                listing: listing,
                onDelete: () => _delete(listing),
                onReturn: _refreshIfMounted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({
    required this.listing,
    required this.onDelete,
    required this.onReturn,
  });

  final Listing listing;
  final VoidCallback onDelete;

  /// Called after returning from an edit/media route so the list reloads.
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: () => context
          .push('/market/listings/${l.id}/edit')
          .then((_) => onReturn()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 15,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                onSelected: (v) {
                  switch (v) {
                    case 'pay':
                      context
                          .push('/pay/listing/${l.id}')
                          .then((_) => onReturn());
                    case 'edit':
                      context
                          .push('/market/listings/${l.id}/edit')
                          .then((_) => onReturn());
                    case 'media':
                      context
                          .push('/market/listings/${l.id}/media')
                          .then((_) => onReturn());
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (l.status == ListingStatus.pendingPayment)
                    PopupMenuItem(
                      value: 'pay',
                      child: Text(context.l10n.sellerPay,
                          style: AppText.tajawal(
                              size: 15,
                              weight: AppText.bold,
                              color: AppColors.primaryGreen)),
                    ),
                  PopupMenuItem(
                      value: 'edit',
                      child: Text(context.l10n.edit, style: AppText.rowLabel)),
                  PopupMenuItem(
                      value: 'media',
                      child: Text(context.l10n.sellerMedia, style: AppText.rowLabel)),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.l10n.delete,
                        style: AppText.tajawal(
                            size: 15,
                            weight: AppText.bold,
                            color: AppColors.logoutText)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip(context, l.status),
              if (l.category != null) ...[
                const SizedBox(width: 8),
                Flexible(child: Text(l.category!.name, style: AppText.muted)),
              ],
            ],
          ),
          if (l.status == ListingStatus.rejected &&
              l.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text(
              l.rejectionReason!,
              style: AppText.tajawal(
                size: 12,
                weight: AppText.medium,
                color: AppColors.logoutText,
              ),
            ),
          ],
          if (l.status == ListingStatus.pendingPayment) ...[
            const SizedBox(height: 12),
            GreenPillButton(
              label: context.l10n.sellerPayNow,
              onTap: () =>
                  context.push('/pay/listing/${l.id}').then((_) => onReturn()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, ListingStatus status) {
    final (Color bg, Color fg) = switch (status) {
      ListingStatus.published => (AppColors.pillBg, AppColors.pillText),
      ListingStatus.rejected ||
      ListingStatus.suspended =>
        (AppColors.logoutBgBottom, AppColors.logoutText),
      ListingStatus.pendingPayment => (const Color(0xFFFFF3D6), const Color(0xFFB7791F)),
      _ => (const Color(0xFFEDEFF1), AppColors.sectionLabel),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        listingStatusLabel(status, context.l10n),
        style: AppText.tajawal(size: 12, weight: AppText.bold, color: fg),
      ),
    );
  }
}
