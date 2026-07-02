import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/routing/deep_link.dart';
import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/listing.dart';
import 'package:iqs_flutter/features/marketplace/data/marketplace_category.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// Marketplace browse (`/market`) — `marketplace_top` banner, category +
/// featured filters, debounced search, paginated featured-first listings.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _query = '';
  int? _category;
  bool _featured = false;
  int _reload = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = _input.text.trim());
    });
  }

  void _bump() => setState(() => _reload++);

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _searchField()),
                    const SizedBox(width: 10),
                    ClayHeaderButton(
                      icon: Icons.storefront_outlined,
                      iconSize: 22,
                      onTap: () => context.push('/market/my-store'),
                    ),
                    const SizedBox(width: 10),
                    ClayHeaderButton(
                      icon: Icons.chevron_left,
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _filterChips(catsAsync),
              ],
            ),
          ),
          _bannerStrip(),
          Expanded(
            child: PaginatedListView<Listing>(
              key: ValueKey('$_category-$_featured-$_query-$_reload'),
              loader: (page) =>
                  ref.read(marketplaceRepositoryProvider).listings(
                        category: _category,
                        featured: _featured ? true : null,
                        q: _query.isEmpty ? null : _query,
                        page: page,
                      ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              emptyTitle: context.l10n.marketNoListings,
              itemBuilder: (context, listing, _) =>
                  _ListingCard(listing: listing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: Clay.card(radius: 16, gradient: AppColors.surface),
      child: TextField(
        controller: _input,
        onChanged: _onSearch,
        textInputAction: TextInputAction.search,
        style: AppText.tajawal(size: 15, weight: AppText.bold),
        cursorColor: AppColors.primaryGreen,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: context.l10n.marketSearchHint,
          hintStyle: AppText.muted,
          icon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onSubmitted: (_) {},
      ),
    );
  }

  Widget _filterChips(AsyncValue<List<MarketplaceCategory>> catsAsync) {
    final leaves = catsAsync.hasValue
        ? flattenLeafCategories(catsAsync.value!)
        : const <MarketplaceCategory>[];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppChip(
            label: context.l10n.marketFeaturedChip,
            active: _featured,
            onTap: () {
              setState(() => _featured = !_featured);
              _bump();
            },
          ),
          const SizedBox(width: 8),
          AppChip(
            label: context.l10n.marketAllChip,
            active: _category == null,
            onTap: () {
              setState(() => _category = null);
              _bump();
            },
          ),
          // Categories failed to load → offer a retry instead of an empty row.
          if (catsAsync.hasError) ...[
            const SizedBox(width: 8),
            AppChip(
              label: context.l10n.retry,
              active: false,
              onTap: () => ref.invalidate(categoriesProvider),
            ),
          ],
          for (final cat in leaves) ...[
            const SizedBox(width: 8),
            AppChip(
              label: cat.name,
              active: _category == cat.id,
              onTap: () {
                setState(() => _category = cat.id);
                _bump();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _bannerStrip() {
    final banners = bannersForPlacement(
      ref.watch(bannersProvider).valueOrNull ?? const [],
      'marketplace_top',
    );
    if (banners.isEmpty) return const SizedBox.shrink();
    final b = banners.first;
    final url = assetUrl(b.image);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () => handleDeepLink(context, b.deepLink),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageBox(url: url ?? '', fit: BoxFit.cover),
                Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.sliderOverlay),
                ),
                Positioned(
                  right: 16,
                  bottom: 12,
                  left: 16,
                  child: Text(
                    b.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppText.tajawal(
                      size: 16,
                      weight: AppText.extraBold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final photo = assetUrl(l.photo);
    final place = [l.governorate, l.city].whereType<String>().join(' · ');
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/listings/${l.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 88,
              height: 88,
              child: photo == null
                  ? Container(
                      color: const Color(0xFFEAF2EC),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_outline,
                          color: AppColors.primaryGreen, size: 34),
                    )
                  : NetworkImageBox(url: photo, width: 88, height: 88),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (l.isFeatured) ...[
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFE0A416)),
                      const SizedBox(width: 4),
                    ],
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
                  ],
                ),
                const SizedBox(height: 6),
                if (l.category != null)
                  Text(l.category!.name, style: AppText.muted),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.muted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.chevron, size: 22),
        ],
      ),
    );
  }
}
