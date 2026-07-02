import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/league.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'match_widgets.dart';

/// Leagues browse (`/leagues`) — the الفرق / Teams entry point (teams are
/// reached via standings rows). Iraqi leagues, drill into league detail.
class LeaguesScreen extends ConsumerWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaguesProvider(true));
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: DetailHeaderRow(title: context.l10n.matchesNavLeagues),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(leaguesProvider(true)),
              data: (leagues) {
                if (leagues.isEmpty) {
                  return EmptyState(title: context.l10n.matchesNavNoLeagues);
                }
                return RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: () async => ref.invalidate(leaguesProvider(true)),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    itemCount: leagues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => _LeagueCard(league: leagues[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.league});
  final League league;

  @override
  Widget build(BuildContext context) {
    final season = league.currentSeason?.label;
    // Real competition logo when available; trophy stays as the fallback.
    final logo = assetUrl(league.logo);
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/leagues/${league.id}'),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: Clay.circle(AppColors.crest(matchCrestColor(league.id))),
            child: logo == null
                ? const Icon(Icons.emoji_events_rounded,
                    color: Colors.white, size: 26)
                : NetworkImageBox(url: logo, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  league.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 16,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (season != null) ...[
                  const SizedBox(height: 4),
                  Text(context.l10n.matchesNavSeasonLabel(season), style: AppText.muted),
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
