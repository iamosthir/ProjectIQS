import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/features/matches/data/standing.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';

/// Shared standings table (header + clay card of rows), reused by the league
/// detail screen and the match-detail Standings tab. Each row taps → team.
class StandingsTable extends StatelessWidget {
  const StandingsTable({super.key, required this.standings, this.highlightTeamIds = const {}});

  final List<Standing> standings;

  /// Team ids to emphasise (e.g. the two teams of the current fixture).
  final Set<int> highlightTeamIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context.l10n),
        const SizedBox(height: 6),
        Container(
          decoration: Clay.card(radius: 20, gradient: AppColors.surface),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < standings.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                StandingRow(
                  standing: standings[i],
                  highlighted: highlightTeamIds.contains(standings[i].team.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(AppLocalizations l) {
    Widget cell(String t, {int flex = 1, TextAlign align = TextAlign.center}) =>
        Expanded(
          flex: flex,
          child: Text(t,
              textAlign: align,
              style: AppText.tajawal(
                  size: 12, weight: AppText.bold, color: AppColors.textMuted)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Fixed-width rank cell — a bare Text (NOT an Expanded that would break
          // inside the SizedBox).
          SizedBox(
            width: 28,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                  size: 12, weight: AppText.bold, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          cell(l.matchesNavColTeam, flex: 4, align: TextAlign.start),
          cell(l.matchesNavColPlayed),
          cell(l.matchesNavColGoalDiff),
          cell(l.matchesNavColPoints),
        ],
      ),
    );
  }
}

class StandingRow extends StatelessWidget {
  const StandingRow({super.key, required this.standing, this.highlighted = false});
  final Standing standing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final s = standing;
    final gd = s.goalsDiff > 0 ? '+${s.goalsDiff}' : '${s.goalsDiff}';
    Widget num(String t, {bool bold = false, Color? color, bool ltr = false}) {
      Widget text = Text(
        t,
        textAlign: TextAlign.center,
        style: AppText.tajawal(
          size: 13,
          weight: bold ? AppText.extraBold : AppText.medium,
          color: color ?? AppColors.textPrimary,
        ),
      );
      // Force LTR for signed numbers (e.g. -3/+5) so the sign doesn't reorder in
      // the RTL paragraph.
      if (ltr) {
        text = Directionality(textDirection: TextDirection.ltr, child: text);
      }
      return Expanded(child: text);
    }

    return Material(
      color: highlighted
          ? AppColors.primaryGreen.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/teams/${s.team.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${s.rank}',
                  textAlign: TextAlign.center,
                  style: AppText.tajawal(
                    size: 14,
                    weight: AppText.extraBold,
                    color: AppColors.textSubtleGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Text(
                  s.team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 14,
                    weight: highlighted ? AppText.extraBold : AppText.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              num('${s.played}'),
              num(gd, ltr: true),
              num('${s.points}', bold: true, color: AppColors.primaryGreen),
            ],
          ),
        ),
      ),
    );
  }
}
