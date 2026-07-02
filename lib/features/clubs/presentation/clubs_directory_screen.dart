import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/clubs/data/club.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
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

/// Clubs directory — the repurposed "الأخبار / News" tab (Decision A). Verified
/// clubs first; search + governorate filter; tap → club profile.
class ClubsDirectoryScreen extends ConsumerStatefulWidget {
  const ClubsDirectoryScreen({super.key});

  @override
  ConsumerState<ClubsDirectoryScreen> createState() =>
      _ClubsDirectoryScreenState();
}

class _ClubsDirectoryScreenState extends ConsumerState<ClubsDirectoryScreen> {
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
                          child: Text(context.l10n.clubsTitle,
                              style: AppText.screenTitle)),
                    ),
                    ClayHeaderButton(
                      icon: Icons.shield_outlined,
                      iconSize: 22,
                      onTap: () => context.push('/my-club'),
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
            child: PaginatedListView<Club>(
              key: ValueKey('$_query-${_gov?.code}-$_reload'),
              loader: (page) => ref.read(clubsRepositoryProvider).clubs(
                    q: _query.isEmpty ? null : _query,
                    governorate: _gov?.code,
                    page: page,
                  ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              emptyTitle: context.l10n.clubsEmpty,
              itemBuilder: (context, club, _) => _ClubCard(club: club),
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
          hintText: context.l10n.clubsSearchHint,
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
        // Dismissing the picker (null) is a no-op — don't clear or refetch.
        if (!mounted || picked == null) return;
        // Re-tapping the already-selected one clears it.
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

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final logo = assetUrl(club.logo);
    final place = [club.governorate, club.city].whereType<String>().join(' · ');
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/clubs/${club.id}'),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: Clay.circle(AppColors.avatar),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: logo == null
                ? const Icon(Icons.shield_outlined, color: Colors.white, size: 28)
                : NetworkImageBox(url: logo, width: 58, height: 58, fit: BoxFit.cover),
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
                      child: Text(
                        club.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.tajawal(
                          size: 16,
                          weight: AppText.extraBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (club.isVerified) ...[
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
}
