import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';
import 'package:iqs_flutter/shared/widgets/governorate_picker.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// Fan-groups directory — the repurposed "الفيديو / Video" tab (Decision B).
/// Official-first; search + governorate filter; tap → fan-group profile.
class FanGroupsDirectoryScreen extends ConsumerStatefulWidget {
  const FanGroupsDirectoryScreen({super.key});

  @override
  ConsumerState<FanGroupsDirectoryScreen> createState() =>
      _FanGroupsDirectoryScreenState();
}

class _FanGroupsDirectoryScreenState
    extends ConsumerState<FanGroupsDirectoryScreen> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Governorate? _gov;
  int _reload = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _query = _input.text.trim();
        _reload++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(width: 50),
                    Expanded(
                      child: Center(
                          child:
                              Text(context.l10n.fanGroupsTitle, style: AppText.screenTitle)),
                    ),
                    ClayHeaderButton(
                      icon: Icons.shield_outlined,
                      iconSize: 22,
                      onTap: () => context.push('/my-fan-group'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _searchField()),
                    const SizedBox(width: 10),
                    _govButton(),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedListView<FanGroup>(
              key: ValueKey('$_query-${_gov?.code}-$_reload'),
              loader: (page) => ref.read(fanGroupsRepositoryProvider).fanGroups(
                    q: _query.isEmpty ? null : _query,
                    governorate: _gov?.code,
                    page: page,
                  ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              emptyTitle: context.l10n.fanGroupsEmpty,
              itemBuilder: (context, group, _) => _FanGroupCard(group: group),
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
          hintText: context.l10n.fanGroupsSearchHint,
          hintStyle: AppText.muted,
          icon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _govButton() {
    return GestureDetector(
      onTap: () async {
        final picked = await showGovernoratePicker(context);
        if (!mounted || picked == null) return;
        final next = picked.code == _gov?.code ? null : picked;
        if (next?.code != _gov?.code) {
          setState(() {
            _gov = next;
            _reload++;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: Clay.headerButton(radius: 16),
        child: Icon(
          _gov == null ? Icons.filter_list_rounded : Icons.filter_alt_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _FanGroupCard extends StatelessWidget {
  const _FanGroupCard({required this.group});
  final FanGroup group;

  @override
  Widget build(BuildContext context) {
    final logo = assetUrl(group.groupLogo);
    final place =
        [group.governorate, group.city].whereType<String>().join(' · ');
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/fan-groups/${group.id}'),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: Clay.circle(AppColors.avatar),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: logo == null
                ? const Icon(Icons.campaign_outlined,
                    color: Colors.white, size: 28)
                : NetworkImageBox(
                    url: logo, width: 58, height: 58, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(group.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.tajawal(
                              size: 16,
                              weight: AppText.extraBold,
                              color: AppColors.textPrimary)),
                    ),
                    if (group.isOfficial) ...[
                      const SizedBox(width: 6),
                      _badge(context.l10n.fanGroupsOfficialBadge),
                    ] else if (group.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          size: 16, color: AppColors.primaryGreen),
                    ],
                  ],
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(place, style: AppText.muted),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_left, color: AppColors.chevron, size: 22),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: AppText.tajawal(
              size: 11, weight: AppText.bold, color: AppColors.pillText)),
    );
  }
}
