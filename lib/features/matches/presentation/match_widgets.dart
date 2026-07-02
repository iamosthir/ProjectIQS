import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/matches/data/fixture.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';

const List<Color> _crestPalette = [
  Color(0xFF16357A),
  Color(0xFF1F53B0),
  Color(0xFF2A2A2A),
  Color(0xFF2F8F3E),
  Color(0xFF1B7A3E),
  Color(0xFF2060C0),
  Color(0xFF15306E),
  Color(0xFFE0A416),
];

/// Stable crest colour from a team id (the design uses coloured star crests).
Color matchCrestColor(int id) => _crestPalette[id % _crestPalette.length];

/// The team crest of the matches-feed card. Renders the real team logo (club
/// crest / country flag) when the API provides one; the design's coloured star
/// remains the fallback for teams without an image.
class TeamCrest extends StatelessWidget {
  const TeamCrest({
    super.key,
    required this.teamId,
    this.logo,
    this.size = 52,
    this.iconSize = 26,
  });

  final int teamId;

  /// Storage-relative path or absolute URL (both handled by [assetUrl]).
  final String? logo;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = assetUrl(logo);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: Clay.circle(AppColors.crest(matchCrestColor(teamId))),
      child: url == null
          ? Icon(Icons.star_rounded, color: Colors.white, size: iconSize)
          : NetworkImageBox(url: url, fit: BoxFit.cover),
    );
  }
}

/// Compact fixture card reused by the league-detail and team-detail fixture
/// lists. Visually matches the matches-feed card; taps drill into `/fixtures/:id`.
class FixtureCard extends StatelessWidget {
  const FixtureCard({super.key, required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    final f = fixture;
    return ClayCard(
      strong: true,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      onTap: () => context.push('/fixtures/${f.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _team(f.home)),
          Expanded(child: _center(context, f)),
          Expanded(child: _team(f.away)),
        ],
      ),
    );
  }

  Widget _team(FixtureTeam team) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamCrest(teamId: team.id, logo: team.logo),
        const SizedBox(height: 10),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.tajawal(
            size: 14,
            weight: AppText.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _center(BuildContext context, Fixture f) {
    final s = f.status;
    final showScore = s.isFinished || s.isLive;
    if (showScore) {
      final pill =
          s.isLive ? context.l10n.matchesNavStatusLive : context.l10n.matchesNavStatusEnded;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${f.home.goals ?? 0} - ${f.away.goals ?? 0}',
              style: AppText.tajawal(
                size: 26,
                weight: AppText.black,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _pill(s.isLive && s.elapsed != null ? "${s.elapsed}'" : pill),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule, size: 18, color: AppColors.textMuted),
        const SizedBox(height: 7),
        Text(
          DateFmt.time(f.datetime, locale: 'ar'),
          style: AppText.tajawal(
            size: 17,
            weight: AppText.extraBold,
            color: AppColors.textSubtleGreen,
          ),
        ),
        const SizedBox(height: 7),
        _pill(context.l10n.matchesNavStatusNotStarted),
      ],
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
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
}

/// Standard back-button header row used by the detail screens (title centered,
/// back chevron on the left per the app's RTL convention).
class DetailHeaderRow extends StatelessWidget {
  const DetailHeaderRow({super.key, required this.title, this.fallbackRoute = '/matches'});

  final String title;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 50),
        Expanded(
          child: Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.screenTitle,
            ),
          ),
        ),
        _BackButton(fallbackRoute: fallbackRoute),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.fallbackRoute});
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.canPop() ? context.pop() : context.go(fallbackRoute),
      child: Container(
        width: 46,
        height: 46,
        decoration: Clay.headerButton(radius: 16),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
      ),
    );
  }
}
