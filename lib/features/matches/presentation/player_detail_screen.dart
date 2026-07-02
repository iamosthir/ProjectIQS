import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/team.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'match_widgets.dart';

/// Player profile (`/players/:id`).
class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerProvider(playerId));
    final title = async.valueOrNull?.name ?? context.l10n.matchesNavPlayerTitle;
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: DetailHeaderRow(title: title),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(playerProvider(playerId)),
              data: (p) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _avatar(p),
                    const SizedBox(height: 16),
                    Text(
                      p.name,
                      textAlign: TextAlign.center,
                      style: AppText.tajawal(
                        size: 22,
                        weight: AppText.extraBold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (p.position != null) ...[
                      const SizedBox(height: 6),
                      Center(child: _positionChip(p.position!)),
                    ],
                    const SizedBox(height: 20),
                    _infoCard(p, context.l10n),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Player p) {
    final url = assetUrl(p.photo);
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: Clay.circle(AppColors.crest(matchCrestColor(p.id))),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: url == null
            ? const Icon(Icons.person, color: Colors.white, size: 56)
            : NetworkImageBox(url: url, width: 110, height: 110),
      ),
    );
  }

  Widget _positionChip(String position) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        position,
        style: AppText.tajawal(
          size: 13,
          weight: AppText.bold,
          color: AppColors.pillText,
        ),
      ),
    );
  }

  Widget _infoCard(Player p, AppLocalizations l) {
    final dob = p.dateOfBirth == null
        ? null
        : DateFormat('d MMMM y', 'ar').format(p.dateOfBirth!);
    final rows = <(IconData, String, String?)>[
      (Icons.flag_outlined, l.matchesNavNationality, p.nationality),
      (Icons.cake_outlined, l.matchesNavDateOfBirth, dob),
      (Icons.height, l.matchesNavHeight, p.height),
      (Icons.monitor_weight_outlined, l.matchesNavWeight, p.weight),
      (Icons.location_on_outlined, l.matchesNavBirthPlace, p.birthPlace),
      if (p.isInjured) (Icons.healing_outlined, l.matchesNavStatus, l.matchesNavInjured),
    ].where((r) => r.$3 != null && r.$3!.isNotEmpty).toList();

    if (rows.isEmpty) {
      return EmptyState(title: l.matchesNavNoExtraInfo);
    }
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(
        children: [
          for (final r in rows) _infoRow(r.$1, r.$2, r.$3!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text(label, style: AppText.muted),
          const Spacer(),
          Flexible(
            child: Text(
              value,
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
    );
  }
}
