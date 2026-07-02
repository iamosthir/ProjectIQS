import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/clubs/application/clubs_providers.dart';
import 'package:iqs_flutter/features/clubs/data/club.dart';
import 'package:iqs_flutter/features/clubs/data/club_detail.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/features/matches/application/matches_providers.dart';
import 'package:iqs_flutter/features/matches/data/team.dart';
import 'package:iqs_flutter/features/matches/presentation/match_widgets.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/network_image_box.dart';
import 'verify_request_sheet.dart';

Future<void> _launch(String raw) async {
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

/// Club profile (`/clubs/:id`). Reuses the NewsScreen chrome (gradient header,
/// crest, info card, tab strip). Tabs: نظرة عامة (overview + org-chart) and
/// الأخبار (news); المباريات/اللاعبون appear only when the club has a `team_id`.
class ClubProfileScreen extends ConsumerStatefulWidget {
  const ClubProfileScreen({super.key, required this.clubId});

  final int clubId;

  @override
  ConsumerState<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends ConsumerState<ClubProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clubDetailProvider(widget.clubId));
    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
      body: AsyncValueView(
        value: async,
        onRetry: () => ref.invalidate(clubDetailProvider(widget.clubId)),
        data: (club) {
          final tabs = <String>[
            context.l10n.clubsTabOverview,
            context.l10n.navNews,
            if (club.teamId != null) ...[
              context.l10n.navMatches,
              context.l10n.clubsTabPlayers,
            ],
          ];
          if (_tab >= tabs.length) _tab = 0;
          return Column(
            children: [
              _header(club),
              const SizedBox(height: 30),
              _tabStrip(tabs),
              Expanded(child: _tabContent(club)),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- header
  Widget _header(ClubDetail club) {
    final logo = assetUrl(club.logo);
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
                  child: Icon(Icons.sports_soccer,
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
                              onTap: () => _showVerify(club.id),
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
                                child: Text(context.l10n.clubsVerifyBadge,
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
                                    child: Text(
                                      club.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.tajawal(
                                          size: 22,
                                          weight: AppText.extraBold,
                                          color: Colors.white),
                                    ),
                                  ),
                                  if (club.isVerified) ...[
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
                                  : context.go('/news'),
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
                              ? Image.asset('assets/club-crest.png',
                                  fit: BoxFit.contain)
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
        Positioned(
          left: 22,
          right: 22,
          bottom: -28,
          child: _infoCard(club),
        ),
      ],
    );
  }

  Widget _infoCard(ClubDetail club) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: Clay.card(radius: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoCol(context.l10n.clubsInfoStadium, club.address ?? '—'),
            _infoDivider(),
            _infoCol(context.l10n.clubsInfoCity,
                club.city ?? club.governorate ?? '—'),
            _infoDivider(),
            _infoCol(context.l10n.clubsInfoFounded,
                club.foundedYear?.toString() ?? '—'),
          ],
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                  size: 13, weight: AppText.medium, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.tajawal(
                  size: 16,
                  weight: AppText.extraBold,
                  color: AppColors.primaryGreen)),
        ],
      ),
    );
  }

  Widget _infoDivider() =>
      Container(width: 1, color: AppColors.infoDivider);

  Widget _tabStrip(List<String> tabs) {
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

  Widget _tabContent(ClubDetail club) {
    // Indices 2/3 only exist when teamId != null.
    if (_tab == 1) return _newsTab(club);
    if (club.teamId != null && _tab == 2) return _matchesTab(club.teamId!);
    if (club.teamId != null && _tab == 3) return _squadTab(club.teamId!);
    return _overviewTab(club);
  }

  // --------------------------------------------------------------- overview
  Widget _overviewTab(ClubDetail club) {
    final hasDescription =
        club.description != null && club.description!.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
      children: [
        if (hasDescription) ...[
          Text(
            club.description!,
            style: AppText.tajawal(
              size: 15,
              weight: AppText.regular,
              color: AppColors.textSubtleGreen,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (club.contact.hasAny) _contactCard(club.contact),
        if (club.titles.isNotEmpty)
          _section(context.l10n.clubsSectionTitles, [
            for (final t in club.titles)
              _simpleRow(Icons.emoji_events_outlined, t.title,
                  [t.competition, t.season, if (t.count > 1) '×${t.count}']
                      .whereType<String>()
                      .join(' · ')),
          ]),
        if (club.board.isNotEmpty)
          _section(context.l10n.clubsSectionBoard, [
            for (final m in club.board)
              _simpleRow(Icons.person_outline, m.name, m.position),
          ]),
        if (club.staff.isNotEmpty)
          _section(context.l10n.clubsSectionStaff, [
            for (final s in club.staff)
              _simpleRow(Icons.badge_outlined, s.name, s.role),
          ]),
        if (club.captains.isNotEmpty)
          _section(context.l10n.clubsSectionCaptains, [
            for (final c in club.captains)
              _simpleRow(
                  Icons.star_outline,
                  c.name,
                  [c.periodFrom, c.periodTo]
                      .whereType<String>()
                      .join(' – ')),
          ]),
        if (club.competitions.isNotEmpty)
          _section(context.l10n.clubsSectionCompetitions, [
            for (final c in club.competitions)
              _simpleRow(Icons.sports_soccer, c.name, c.season),
          ]),
        if (!hasDescription &&
            !club.contact.hasAny &&
            club.titles.isEmpty &&
            club.board.isEmpty &&
            club.staff.isEmpty &&
            club.captains.isEmpty &&
            club.competitions.isEmpty)
          SizedBox(
              height: 200,
              child: EmptyState(title: context.l10n.clubsNoInfo)),
      ],
    );
  }

  Widget _contactCard(ClubContact c) {
    final items = <(IconData, String, String)>[
      if (c.phone != null && c.phone!.isNotEmpty)
        (Icons.call, c.phone!, 'tel:${c.phone}'),
      if (c.email != null && c.email!.isNotEmpty)
        (Icons.email_outlined, c.email!, 'mailto:${c.email}'),
      if (c.website != null && c.website!.isNotEmpty)
        (Icons.language, c.website!, c.website!),
      if (c.facebook != null && c.facebook!.isNotEmpty)
        (Icons.facebook, 'Facebook', c.facebook!),
      if (c.instagram != null && c.instagram!.isNotEmpty)
        (Icons.camera_alt_outlined, 'Instagram', c.instagram!),
      if (c.twitter != null && c.twitter!.isNotEmpty)
        (Icons.alternate_email, 'Twitter', c.twitter!),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: Clay.card(radius: 20, gradient: AppColors.surface),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.divider),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launch(items[i].$3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Icon(items[i].$1,
                            size: 20, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(items[i].$2,
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
            ],
          ],
        ),
      ),
    );
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

  Widget _simpleRow(IconData icon, String title, String? subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: Clay.settingsTile(),
            child: Icon(icon, size: 20, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowLabel),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.muted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------- news
  Widget _newsTab(ClubDetail club) {
    return PaginatedListView<ClubNews>(
      key: ValueKey('club-news-${club.id}'),
      loader: (page) => ref
          .read(clubsRepositoryProvider)
          .clubNews(club.id, clubName: club.name, page: page),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
      emptyTitle: context.l10n.clubsNoNews,
      itemBuilder: (context, news, _) => _NewsCard(news: news, clubId: club.id),
    );
  }

  // --------------------------------------------------------- team-derived
  Widget _matchesTab(int teamId) {
    final async = ref.watch(teamFixturesProvider(teamId));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(teamFixturesProvider(teamId)),
      data: (fixtures) => fixtures.isEmpty
          ? EmptyState(title: context.l10n.clubsNoMatches)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              itemCount: fixtures.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) => FixtureCard(fixture: fixtures[i]),
            ),
    );
  }

  Widget _squadTab(int teamId) {
    final async = ref.watch(squadProvider(teamId));
    return AsyncValueView(
      value: async,
      onRetry: () => ref.invalidate(squadProvider(teamId)),
      data: (players) => players.isEmpty
          ? EmptyState(title: context.l10n.clubsNoSquad)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
              itemCount: players.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _SquadRow(player: players[i]),
            ),
    );
  }

  void _showVerify(int clubId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VerifyRequestSheet(clubId: clubId),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news, required this.clubId});
  final ClubNews news;
  final int clubId;

  @override
  Widget build(BuildContext context) {
    final cover = assetUrl(news.cover);
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      onTap: () => context.push('/clubs/$clubId/news/${news.id}'),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 104,
              height: 78,
              child: cover == null
                  ? Container(
                      color: const Color(0xFFEAF2EC),
                      alignment: Alignment.center,
                      child: const Icon(Icons.article_outlined,
                          color: AppColors.primaryGreen),
                    )
                  : NetworkImageBox(url: cover, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tajawal(
                    size: 16,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(DateFmt.relative(news.publishedAt), style: AppText.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadRow extends StatelessWidget {
  const _SquadRow({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      onTap: () => context.push('/players/${player.id}'),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              player.number?.toString() ?? '–',
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                size: 15,
                weight: AppText.extraBold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowLabel),
          ),
          if (player.position != null)
            Text(player.position!, style: AppText.muted),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_left, color: AppColors.chevron, size: 20),
        ],
      ),
    );
  }
}
