import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/listing.dart';
import 'package:iqs_flutter/features/marketplace/data/marketplace_category.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// Listing media manager (`/market/listings/:id/media`) — upload images
/// (gallery). The backend has no media-delete endpoint, so this is upload-only.
class MediaManagerScreen extends ConsumerStatefulWidget {
  const MediaManagerScreen({super.key, required this.listingId});

  final int listingId;

  @override
  ConsumerState<MediaManagerScreen> createState() => _MediaManagerScreenState();
}

class _MediaManagerScreenState extends ConsumerState<MediaManagerScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload(int imageLimit, int currentCount) async {
    if (imageLimit > 0 && currentCount >= imageLimit) {
      _snack(context.l10n.sellerImageLimitReached);
      return;
    }
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(marketplaceRepositoryProvider).uploadMedia(
            widget.listingId,
            filePath: picked.path,
            type: 'image',
          );
      ref.invalidate(listingDetailProvider(widget.listingId));
      if (!mounted) return;
      _snack(context.l10n.sellerImageUploaded);
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listingDetailProvider(widget.listingId));
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const [];
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
                    child: Text(context.l10n.sellerListingMediaTitle,
                      style: AppText.screenTitle),
                  ),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/market/my-listings'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () =>
                  ref.invalidate(listingDetailProvider(widget.listingId)),
              data: (listing) {
                final images = listing.media
                    .where((m) => m.type == 'image')
                    .toList();
                final limit = _imageLimit(cats, listing.category?.id);
                return _body(listing, images, limit);
              },
            ),
          ),
        ],
      ),
    );
  }

  int _imageLimit(List<MarketplaceCategory> cats, int? categoryId) {
    if (categoryId == null) return 0;
    for (final c in flattenLeafCategories(cats)) {
      if (c.id == categoryId) return c.fieldSchema?.imageLimit ?? 0;
    }
    return 0;
  }

  Widget _body(Listing listing, List<ListingMedia> images, int limit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            limit > 0
                ? context.l10n.sellerPhotosCountLimited(images.length, limit)
                : context.l10n.sellerPhotosCount(images.length),
            style: AppText.sectionHeader,
          ),
          const SizedBox(height: 14),
          if (images.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: Clay.card(radius: 18, gradient: AppColors.surface),
              child: Text(context.l10n.sellerNoPhotosYet, style: AppText.muted),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final m in images)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 104,
                      height: 104,
                      child: NetworkImageBox(
                        url: assetUrl(m.url) ?? '',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          _uploading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LoadingState(),
                )
              : Clay3DButton(
                  label: context.l10n.sellerAddPhoto,
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
                  leading:
                      const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 20),
                  onTap: () => _pickAndUpload(limit, images.length),
                ),
          const SizedBox(height: 12),
          Text(
            context.l10n.sellerMediaAdminNote,
            textAlign: TextAlign.center,
            style: AppText.muted,
          ),
        ],
      ),
    );
  }
}
