import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/fixture.dart';
import 'package:iqs_flutter/features/matches/data/prediction.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';

/// Crowd-prediction card with interactive scoreline voting (`/fixtures/:id`
/// predictions). Open while the fixture is scheduled; upserts the caller's
/// `{home, away}` scoreline; shows vote-share bars + the correct-predictions link.
class PredictionSection extends ConsumerStatefulWidget {
  const PredictionSection({super.key, required this.fixture});

  final Fixture fixture;

  @override
  ConsumerState<PredictionSection> createState() => _PredictionSectionState();
}

class _PredictionSectionState extends ConsumerState<PredictionSection> {
  int? _home;
  int? _away;
  bool _submitting = false;

  int _homeScore(PredictionSummary s) => _home ?? s.myPrediction?.home ?? 0;
  int _awayScore(PredictionSummary s) => _away ?? s.myPrediction?.away ?? 0;

  Future<void> _submit(int fixtureId, int home, int away) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(matchesRepositoryProvider)
          .predict(fixtureId, home: home, away: away);
      if (!mounted) return;
      setState(() {
        _home = null;
        _away = null;
      });
      ref.invalidate(predictionsSummaryProvider(fixtureId));
      ref.invalidate(fixtureDetailProvider(fixtureId));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.matchSocialPredictionSaved)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    final async = ref.watch(predictionsSummaryProvider(f.id));
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: AsyncValueView(
        value: async,
        onRetry: () => ref.invalidate(predictionsSummaryProvider(f.id)),
        loading: const SizedBox(height: 120, child: LoadingState()),
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.matchSocialCrowdPredictions,
                  style: AppText.tajawal(
                    size: 16,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(s.hasVotes ? context.l10n.matchSocialPredictionsCount(s.total) : context.l10n.matchSocialNoPredictions,
                    style: AppText.muted),
              ],
            ),
            const SizedBox(height: 16),
            _bar(context.l10n.matchSocialTeamWins(f.home.name), s.homePercent, s.countsHome),
            const SizedBox(height: 10),
            _bar(context.l10n.matchSocialDraw, s.drawPercent, s.countsDraw),
            const SizedBox(height: 10),
            _bar(context.l10n.matchSocialTeamWins(f.away.name), s.awayPercent, s.countsAway),
            const SizedBox(height: 18),
            if (s.isOpen)
              _voteBox(f, s)
            else
              _closedBox(s),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () => context.push('/fixtures/${f.id}/predictions/correct'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.l10n.matchSocialCorrectPredictionsLink,
                    style: AppText.tajawal(
                      size: 13,
                      weight: AppText.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voteBox(Fixture f, PredictionSummary s) {
    final home = _homeScore(s);
    final away = _awayScore(s);
    final hasPrediction = s.myPrediction != null;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: Clay.card(radius: 18, gradient: AppColors.sectionTile),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _stepper(f.home.name, home, (v) => setState(() => _home = v))),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text('-',
                    style: AppText.tajawal(
                        size: 24,
                        weight: AppText.black,
                        color: AppColors.textMuted)),
              ),
              Expanded(child: _stepper(f.away.name, away, (v) => setState(() => _away = v))),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _submitting
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LoadingState(),
              )
            : GreenPillButton(
                label: hasPrediction ? context.l10n.matchSocialEditPrediction : context.l10n.matchSocialSavePrediction,
                onTap: () => _submit(f.id, home, away),
              ),
      ],
    );
  }

  Widget _stepper(String teamName, int value, ValueChanged<int> onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          teamName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.tajawal(
            size: 13,
            weight: AppText.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepBtn(Icons.remove, () {
              if (value > 0) onChanged(value - 1);
            }),
            SizedBox(
              width: 44,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppText.tajawal(
                    size: 26,
                    weight: AppText.black,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            _stepBtn(Icons.add, () {
              if (value < 99) onChanged(value + 1);
            }),
          ],
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: Clay.circle(AppColors.primary),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _closedBox(PredictionSummary s) {
    final my = s.myPrediction;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: Clay.card(radius: 16, gradient: AppColors.sectionTile),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              my == null
                  ? context.l10n.matchSocialPredictionsClosed
                  : context.l10n.matchSocialYourPrediction('${my.home} - ${my.away}'),
              style: AppText.tajawal(
                size: 14,
                weight: AppText.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (my?.isCorrect == true)
            const Icon(Icons.check_circle, size: 20, color: AppColors.primaryGreen),
        ],
      ),
    );
  }

  Widget _bar(String label, double percent, int count) {
    final pct = percent.clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tajawal(
                  size: 13,
                  weight: AppText.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}% ($count)',
              style: AppText.tajawal(
                size: 12,
                weight: AppText.extraBold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(height: 9, color: AppColors.pillBg),
              FractionallySizedBox(
                widthFactor: pct / 100,
                child: Container(
                  height: 9,
                  decoration: const BoxDecoration(gradient: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
