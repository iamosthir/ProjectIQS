import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/features/discovery/data/search_result.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

/// Global search (`/search`) — debounced query (≥2 chars), type filter chips,
/// results routed by type+id.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _type;

  List<(String, String?)> _types(BuildContext context) => [
        (context.l10n.discoveryTypeAll, null),
        (context.l10n.discoveryTypeTeams, 'team'),
        (context.l10n.discoveryTypePlayers, 'player'),
        (context.l10n.discoveryTypeClubs, 'club'),
        (context.l10n.discoveryTypeFanGroups, 'fan_group'),
        (context.l10n.discoveryTypeMarket, 'listing'),
      ];

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      // Read the live controller text (not the captured value) so a clear/edit
      // that landed during the debounce window can't be resurrected.
      setState(() => _query = _input.text.trim());
    });
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'team':
        return Icons.shield_outlined;
      case 'player':
        return Icons.person_outline;
      case 'club':
        return Icons.groups_outlined;
      case 'fan_group':
        return Icons.campaign_outlined;
      case 'listing':
        return Icons.storefront_outlined;
      default:
        return Icons.search;
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _searchField()),
                    const SizedBox(width: 10),
                    ClayHeaderButton(
                      icon: Icons.chevron_left,
                      onTap: () =>
                          context.canPop() ? context.pop() : context.go('/home'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _typeChips(),
              ],
            ),
          ),
          Expanded(child: _results()),
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
        autofocus: true,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        style: AppText.tajawal(size: 15, weight: AppText.bold),
        cursorColor: AppColors.primaryGreen,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: context.l10n.discoverySearchHint,
          hintStyle: AppText.muted,
          icon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
          suffixIcon: _input.text.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    _debounce?.cancel();
                    _input.clear();
                    setState(() => _query = '');
                  },
                  child: const Icon(Icons.close,
                      size: 18, color: AppColors.textMuted),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _typeChips() {
    final types = _types(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            AppChip(
              label: types[i].$1,
              active: _type == types[i].$2,
              onTap: () => setState(() => _type = types[i].$2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _results() {
    if (_query.length < 2) {
      return EmptyState(
        title: context.l10n.discoverySearchInIqs,
        subtitle: context.l10n.discoverySearchMinChars,
        icon: Icons.search,
      );
    }
    final async = ref.watch(searchProvider((q: _query, type: _type)));
    return AsyncValueView(
      value: async,
      onRetry: () =>
          ref.invalidate(searchProvider((q: _query, type: _type))),
      data: (results) {
        if (results.isEmpty) {
          return EmptyState(title: context.l10n.noResults);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ResultRow(
            result: results[i],
            icon: _typeIcon(results[i].type),
          ),
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.icon});

  final SearchResult result;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final image = assetUrl(result.image);
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      onTap: () {
        final route = result.route;
        if (route != null) context.push(route);
      },
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: Clay.circle(AppColors.crest(AppColors.primaryGreen)),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: image == null
                ? Icon(icon, color: Colors.white, size: 22)
                : NetworkImageBox(url: image, width: 46, height: 46),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 15,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (result.subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(result.subtitle!, style: AppText.muted),
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
