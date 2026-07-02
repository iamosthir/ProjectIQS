import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'fan_group_verify_sheet.dart';

Future<void> _launch(String? raw) async {
  if (raw == null || raw.isEmpty) return;
  var url = raw;
  if (!url.startsWith('http') &&
      !url.startsWith('tel:') &&
      !url.startsWith('mailto:')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  if (uri != null && uri.hasScheme) {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {/* ignore */}
  }
}

/// Fan-group profile (`/fan-groups/:id`): overview (description + contact +
/// documents), photos, videos, chants.
class FanGroupProfileScreen extends ConsumerStatefulWidget {
  const FanGroupProfileScreen({super.key, required this.fanGroupId});

  final int fanGroupId;

  @override
  ConsumerState<FanGroupProfileScreen> createState() =>
      _FanGroupProfileScreenState();
}

class _FanGroupProfileScreenState extends ConsumerState<FanGroupProfileScreen> {
  int _tab = 0;
  List<String> _tabLabels(BuildContext context) => [
        context.l10n.fanGroupsTabOverview,
        context.l10n.fanGroupsTabPhotos,
        context.l10n.fanGroupsTabVideos,
        context.l10n.fanGroupsTabChants,
      ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fanGroupDetailProvider(widget.fanGroupId));
    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
      body: AsyncValueView(
        value: async,
        onRetry: () => ref.invalidate(fanGroupDetailProvider(widget.fanGroupId)),
        data: (fg) => Column(
          children: [
            _header(fg),
            const SizedBox(height: 30),
            _tabStrip(),
            Expanded(child: _content(fg)),
          ],
        ),
      ),
    );
  }

  Widget _header(FanGroupDetail fg) {
    final logo = assetUrl(fg.group.groupLogo);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(38)),
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerNews),
            padding: const EdgeInsets.only(bottom: 30),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Opacity(
                    opacity: 0.22,
                    child:
                        Image.asset('assets/header-banner.png', fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 18,
                  child: Icon(Icons.campaign,
                      size: 140, color: Colors.white.withValues(alpha: 0.10)),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _showVerify(fg.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 9, horizontal: 18),
                                decoration: BoxDecoration(
                                  gradient: AppColors.headerBtn,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                      spreadRadius: -4,
                                    ),
                                  ],
                                ),
                                child: Text(context.l10n.fanGroupsVerifyAction,
                                    style: AppText.tajawal(
                                        size: 14,
                                        weight: AppText.bold,
                                        color: Colors.white)),
                              ),
                            ),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(fg.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.tajawal(
                                            size: 22,
                                            weight: AppText.extraBold,
                                            color: Colors.white)),
                                  ),
                                  if (fg.group.isOfficial ||
                                      fg.group.isVerified) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified,
                                        size: 18, color: Colors.white),
                                  ],
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/video'),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: Clay.headerButton(radius: 16),
                                child: const Icon(Icons.chevron_left,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4D000000),
                              blurRadius: 18,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 130,
                          height: 130,
                          child: logo == null
                              ? Container(
                                  decoration: Clay.circle(AppColors.avatar),
                                  child: const Icon(Icons.campaign,
                                      color: Colors.white, size: 56),
                                )
                              : ClipOval(
                                  child: NetworkImageBox(
                                      url: logo, fit: BoxFit.cover)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(left: 22, right: 22, bottom: -28, child: _countsCard(fg)),
      ],
    );
  }

  Widget _countsCard(FanGroupDetail fg) {
    Widget col(String label, int n) => Expanded(
          child: Column(
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text('$n',
                    style: AppText.tajawal(
                        size: 18,
                        weight: AppText.extraBold,
                        color: AppColors.primaryGreen)),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppText.muted),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: Clay.card(radius: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            col(context.l10n.fanGroupsTabPhotos, fg.photosCount),
            Container(width: 1, color: AppColors.infoDivider),
            col(context.l10n.fanGroupsTabVideos, fg.videosCount),
            Container(width: 1, color: AppColors.infoDivider),
            col(context.l10n.fanGroupsTabChants, fg.chantsCount),
          ],
        ),
      ),
    );
  }

  Widget _tabStrip() {
    final tabs = _tabLabels(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(11),
      decoration: Clay.card(radius: 22, gradient: AppColors.sectionTile),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              AppChip(
                label: tabs[i],
                active: _tab == i,
                onTap: () => setState(() => _tab = i),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content(FanGroupDetail fg) {
    switch (_tab) {
      case 1:
        return _mediaTab(fg.id, 'image');
      case 2:
        return _mediaTab(fg.id, 'video');
      case 3:
        return _chantsTab(fg.id);
      default:
        return _overviewTab(fg);
    }
  }

  // -------------------------------------------------------------- overview
  Widget _overviewTab(FanGroupDetail fg) {
    final hasDescription =
        fg.description != null && fg.description!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      children: [
        if (hasDescription) ...[
          Text(fg.description!,
              style: AppText.tajawal(
                  size: 15,
                  weight: AppText.regular,
                  color: AppColors.textSubtleGreen,
                  height: 1.8)),
          const SizedBox(height: 20),
        ],
        if (fg.contact.hasAny) _contactCard(fg.contact),
        if (fg.documents.isNotEmpty)
          _section(context.l10n.fanGroupsDocuments, [
            for (final d in fg.documents)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launch(assetUrl(d.url)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 20, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(child: Text(d.title, style: AppText.rowLabel)),
                        const Icon(Icons.download_rounded,
                            size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        if (!hasDescription && !fg.contact.hasAny && fg.documents.isEmpty)
          SizedBox(height: 200, child: EmptyState(title: context.l10n.fanGroupsNoInfo)),
      ],
    );
  }

  Widget _contactCard(FanGroupContact c) {
    final items = <(IconData, String, String)>[
      if (c.phone != null && c.phone!.isNotEmpty)
        (Icons.call, c.phone!, 'tel:${c.phone}'),
      if (c.facebook != null && c.facebook!.isNotEmpty)
        (Icons.facebook, 'Facebook', c.facebook!),
      if (c.instagram != null && c.instagram!.isNotEmpty)
        (Icons.camera_alt_outlined, 'Instagram', c.instagram!),
      if (c.twitter != null && c.twitter!.isNotEmpty)
        (Icons.alternate_email, 'Twitter', c.twitter!),
    ];
    return _section(context.l10n.fanGroupsContact, [
      for (final it in items)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _launch(it.$3),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Row(
                children: [
                  Icon(it.$1, size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(it.$2,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.rowLabel),
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      size: 16, color: AppColors.chevron),
                ],
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 10),
            child: Text(title, style: AppText.sectionHeader),
          ),
          Container(
            decoration: Clay.card(radius: 20, gradient: AppColors.surface),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- media
  Widget _mediaTab(int id, String type) {
    return PaginatedListView<FanGroupMedia>(
      key: ValueKey('media-$id-$type'),
      loader: (page) => ref
          .read(fanGroupsRepositoryProvider)
          .fanGroupMedia(id, type: type, page: page),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      emptyTitle: type == 'video'
          ? context.l10n.fanGroupsNoVideos
          : context.l10n.fanGroupsNoPhotos,
      itemBuilder: (context, m, _) =>
          type == 'video' ? _videoTile(m) : _photoTile(m),
    );
  }

  Widget _photoTile(FanGroupMedia m) {
    final url = assetUrl(m.url);
    return GestureDetector(
      onTap: () => _launch(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: NetworkImageBox(url: url ?? '', fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _videoTile(FanGroupMedia m) {
    final thumb = assetUrl(m.thumbnail);
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(10),
      onTap: () => _launch(assetUrl(m.url)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumb == null
                      ? Container(color: AppColors.sliderBg)
                      : NetworkImageBox(url: thumb, fit: BoxFit.cover),
                  const Center(
                    child: Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 34),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(m.title ?? context.l10n.fanGroupsVideoDefaultTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.tajawal(
                    size: 15,
                    weight: AppText.bold,
                    color: AppColors.textPrimary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- chants
  Widget _chantsTab(int id) {
    final async = ref.watch(fanGroupChantsProvider(id));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(fanGroupChantsProvider(id)),
      data: (chants) => chants.isEmpty
          ? EmptyState(title: context.l10n.fanGroupsNoChants)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              itemCount: chants.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _ChantCard(chant: chants[i]),
            ),
    );
  }

  void _showVerify(int id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FanGroupVerifySheet(fanGroupId: id),
    );
  }
}

class _ChantCard extends StatelessWidget {
  const _ChantCard({required this.chant});
  final FanGroupChant chant;

  @override
  Widget build(BuildContext context) {
    final thumb = assetUrl(chant.thumbnail);
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _launch(assetUrl(chant.video)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 96,
                    height: 64,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        thumb == null
                            ? Container(color: AppColors.sliderBg)
                            : NetworkImageBox(url: thumb, fit: BoxFit.cover),
                        const Center(
                          child: Icon(Icons.play_circle_fill,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(chant.title,
                    style: AppText.tajawal(
                        size: 16,
                        weight: AppText.extraBold,
                        color: AppColors.textPrimary,
                        height: 1.4)),
              ),
            ],
          ),
          if (chant.lyrics != null && chant.lyrics!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(chant.lyrics!,
                style: AppText.tajawal(
                    size: 14,
                    weight: AppText.regular,
                    color: AppColors.textSubtleGreen,
                    height: 1.9)),
          ],
        ],
      ),
    );
  }
}
