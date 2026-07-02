import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/listing.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

Future<void> _launch(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && uri.hasScheme) {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {/* ignore */}
  }
}

/// Listing detail (`/listings/:id`). Increments views server-side. Contact
/// button reveals channels via `POST .../contact`.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingDetailProvider(listingId));
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
                        Text(context.l10n.marketListingDetailsTitle, style: AppText.screenTitle),
                  ),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/market'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(listingDetailProvider(listingId)),
              data: (l) => _body(context, l),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Listing l) {
    final photo = assetUrl(l.photo);
    final infoRows = <(String, String?)>[
      (context.l10n.marketInfoName, l.fullName),
      (context.l10n.marketInfoAge, l.age?.toString()),
      (context.l10n.marketInfoNationality, l.nationality),
      (context.l10n.governorate, l.governorate),
      (context.l10n.marketInfoCity, l.city),
    ].where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: NetworkImageBox(url: photo, fit: BoxFit.cover),
              ),
            ),
          if (photo != null) const SizedBox(height: 16),
          Row(
            children: [
              if (l.isFeatured) ...[
                const Icon(Icons.star_rounded, size: 20, color: Color(0xFFE0A416)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  l.title,
                  style: AppText.tajawal(
                    size: 21,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (l.category != null) _chip(l.category!.name),
              if (l.store != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(l.store!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.muted),
                      ),
                      if (l.store!.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: AppColors.primaryGreen),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (l.rejectionReason != null) ...[
            const SizedBox(height: 12),
            _rejectionBox(l.rejectionReason!),
          ],
          const SizedBox(height: 18),
          if (infoRows.isNotEmpty) _infoCard(infoRows),
          if (l.attributes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _attributesCard(l.attributes),
          ],
          const SizedBox(height: 16),
          _statsRow(context, l),
          if (l.cv != null && l.cv!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _cvButton(context, l.cv!),
          ],
          const SizedBox(height: 22),
          if (l.contactAvailable != false)
            Clay3DButton(
              label: context.l10n.marketContact,
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
              height: 60,
              radius: 20,
              leading: const Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 20),
              onTap: () => _showContactSheet(context, l.id),
            ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppText.tajawal(
          size: 12,
          weight: AppText.bold,
          color: AppColors.pillText,
        ),
      ),
    );
  }

  Widget _rejectionBox(String reason) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.logoutBgBottom,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.logoutBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 18, color: AppColors.logoutText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(reason,
                style: AppText.tajawal(
                    size: 13,
                    weight: AppText.medium,
                    color: AppColors.logoutText)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(List<(String, String?)> rows) {
    return Container(
      decoration: Clay.card(radius: 20, gradient: AppColors.surface),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(r.$1, style: AppText.muted),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      r.$2!,
                      textAlign: TextAlign.end,
                      style: AppText.tajawal(
                        size: 14,
                        weight: AppText.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _attributesCard(List<ListingAttribute> attrs) {
    return Container(
      decoration: Clay.card(radius: 20, gradient: AppColors.surface),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        children: [
          for (final a in attrs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(a.label, style: AppText.muted),
                  const Spacer(),
                  Flexible(
                    child: Text(a.value,
                        textAlign: TextAlign.end,
                        style: AppText.tajawal(
                            size: 14,
                            weight: AppText.bold,
                            color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, Listing l) {
    return Row(
      children: [
        _stat(Icons.visibility_outlined,
            context.l10n.marketViewsCount(l.viewsCount)),
        const SizedBox(width: 18),
        _stat(Icons.chat_bubble_outline,
            context.l10n.marketContactsCount(l.contactsCount)),
      ],
    );
  }

  Widget _stat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(text, style: AppText.muted),
      ],
    );
  }

  Widget _cvButton(BuildContext context, String cv) {
    final url = assetUrl(cv);
    return GestureDetector(
      onTap: () => url == null ? null : _launch(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: Clay.card(radius: 16, gradient: AppColors.surface),
        child: Row(
          children: [
            const Icon(Icons.description_outlined,
                size: 20, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
            Text(context.l10n.marketCvLabel, style: AppText.rowLabel),
            const Spacer(),
            const Icon(Icons.download_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showContactSheet(BuildContext context, int listingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(listingId: listingId),
    );
  }
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.listingId});
  final int listingId;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late Future<ListingContact> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(marketplaceRepositoryProvider).contact(widget.listingId);
  }

  void _retry() {
    setState(() {
      _future =
          ref.read(marketplaceRepositoryProvider).contact(widget.listingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.screenBgWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.marketContactChannels, style: AppText.sectionHeader),
            const SizedBox(height: 16),
            FutureBuilder<ListingContact>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: LoadingState(),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ErrorState(
                      message: context.l10n.marketContactFetchError,
                      onRetry: _retry,
                    ),
                  );
                }
                final c = snap.data!;
                if (!c.available || !c.hasChannel) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.l10n.marketNoDirectContact,
                      textAlign: TextAlign.center,
                      style: AppText.muted,
                    ),
                  );
                }
                return Column(
                  children: [
                    if (c.phone != null && c.phone!.isNotEmpty)
                      _channel(Icons.call, context.l10n.marketChannelCall, c.phone!,
                          () => _launch('tel:${c.phone}')),
                    if (c.whatsapp != null && c.whatsapp!.isNotEmpty)
                      _channel(Icons.chat, context.l10n.marketChannelWhatsapp, c.whatsapp!, () {
                        // wa.me needs a digits-only international number (no '+').
                        final wa =
                            c.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
                        _launch('https://wa.me/$wa');
                      }),
                    if (c.email != null && c.email!.isNotEmpty)
                      _channel(Icons.email_outlined, context.l10n.marketChannelEmail, c.email!,
                          () => _launch('mailto:${c.email}')),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _channel(IconData icon, String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: Clay.card(radius: 16, gradient: AppColors.surface),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: Clay.settingsTile(),
                child: Icon(icon, size: 20, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppText.rowLabel),
                  const SizedBox(height: 2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(value, style: AppText.muted),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_left,
                  size: 20, color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }
}
