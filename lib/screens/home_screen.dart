import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/deep_link.dart';
import '../core/util/asset_url.dart';
import '../core/util/date_fmt.dart';
import '../features/clubs/data/club.dart';
import '../features/discovery/application/discovery_providers.dart';
import '../features/notifications/application/notifications_providers.dart';
import '../features/discovery/data/app_banner.dart';
import '../shared/l10n/l10n_ext.dart';
import '../shared/widgets/app_states.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_header.dart';
import '../widgets/clay_card.dart';
import '../widgets/clay_icon_button.dart';
import '../widgets/clay_section_tile.dart';
import '../widgets/network_image_box.dart';

/// Home tab for IQS — green header (scrolls), an auto-advancing featured
/// slider, the "أقسام التطبيق" 4-up section grid, and a "أحدث الأخبار" list.
///
/// Phase 3: the slider is fed by `GET /banners` (`home_top`, ordered by
/// position, tap → deep-link); the news strip aggregates the latest club news
/// (no global news endpoint exists). The widget tree/styling is unchanged —
/// only the data source and the section-tile navigation targets.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onSelectTab});

  /// Switches the global bottom-nav tab (0 home / 1 matches / 2 news / 3 video).
  final ValueChanged<int>? onSelectTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController;
  Timer? _timer;
  int _slide = 0;

  List<AppBanner> _homeTopBanners() => bannersForPlacement(
        ref.read(bannersProvider).valueOrNull ?? const [],
        'home_top',
      );

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final count = _homeTopBanners().length;
      if (count < 2) return;
      final next = (_slide + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToSlide(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSelectTab = widget.onSelectTab;
    final bannersAsync = ref.watch(bannersProvider);
    final newsAsync = ref.watch(latestNewsProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildSlider(bannersAsync),
            _buildSectionsHeader(),
            _buildSectionsGrid(onSelectTab),
            _buildNewsHeader(onSelectTab),
            _buildNewsList(newsAsync, onSelectTab),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- header
  Widget _buildHeader() {
    return AppHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClayHeaderButton(
                icon: Icons.menu_rounded,
                onTap: () => context.push('/search'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.homeGreeting,
                    style: AppText.tajawal(
                      size: 23,
                      weight: AppText.extraBold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              ),
              Consumer(
                builder: (context, ref, _) {
                  final unread =
                      (ref.watch(unreadCountProvider).valueOrNull ?? 0) > 0;
                  return ClayHeaderButton(
                    icon: Icons.notifications_none_rounded,
                    badge: unread,
                    onTap: () => context.push('/notifications'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              context.l10n.homeSubtitle,
              style: AppText.tajawal(
                size: 14,
                weight: AppText.medium,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- slider
  Widget _buildSlider(AsyncValue<List<AppBanner>> bannersAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: AppColors.sliderBg,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF144628).withValues(alpha: 0.40),
                blurRadius: 36,
                offset: const Offset(0, 20),
                spreadRadius: -10,
              ),
              BoxShadow(
                color: const Color(0xFF144628).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
          ),
          child: bannersAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (all) {
              final banners = bannersForPlacement(all, 'home_top');
              if (banners.isEmpty) return const SizedBox.shrink();
              return Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: banners.length,
                    onPageChanged: (i) => setState(() => _slide = i),
                    itemBuilder: (context, i) => _SlideCard(
                      url: assetUrl(banners[i].image) ?? '',
                      title: banners[i].title,
                      onTap: () => handleDeepLink(context, banners[i].deepLink),
                    ),
                  ),
                  if (banners.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < banners.length; i++) ...[
                            if (i != 0) const SizedBox(width: 7),
                            GestureDetector(
                              onTap: () => _goToSlide(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: i == _slide ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _slide
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- sections
  Widget _buildSectionsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.homeSectionsTitle, style: AppText.sectionHeader),
          GestureDetector(
            onTap: () => context.push('/market'),
            child: Text(
              context.l10n.seeAll,
              style: AppText.tajawal(
                size: 13,
                weight: AppText.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid(ValueChanged<int>? onSelectTab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClaySectionTile(
              icon: Icons.article_rounded,
              label: context.l10n.navNews,
              onTap: () => onSelectTab?.call(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClaySectionTile(
              icon: Icons.emoji_events_rounded,
              label: context.l10n.navMatches,
              onTap: () => onSelectTab?.call(1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClaySectionTile(
              icon: Icons.smart_display_rounded,
              label: context.l10n.navVideo,
              onTap: () => onSelectTab?.call(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClaySectionTile(
              icon: Icons.groups_rounded,
              label: context.l10n.homeSectionTeams,
              onTap: () => context.push('/leagues'),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ latest news
  Widget _buildNewsHeader(ValueChanged<int>? onSelectTab) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 24, 14, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.homeLatestNewsTitle, style: AppText.sectionHeader),
          GestureDetector(
            onTap: () => onSelectTab?.call(2),
            child: Text(
              context.l10n.seeAll,
              style: AppText.tajawal(
                size: 13,
                weight: AppText.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsList(
    AsyncValue<List<ClubNews>> newsAsync,
    ValueChanged<int>? onSelectTab,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: newsAsync.when(
        loading: () => const SizedBox(height: 120, child: LoadingState()),
        error: (e, _) => SizedBox(
          height: 140,
          child: appErrorView(
            e,
            onRetry: () => ref.invalidate(latestNewsProvider),
          ),
        ),
        data: (news) {
          if (news.isEmpty) {
            return SizedBox(
              height: 110,
              child: EmptyState(title: context.l10n.homeNoNews),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < news.length; i++) ...[
                if (i != 0) const SizedBox(height: 14),
                _NewsRow(
                  title: news[i].title,
                  time: DateFmt.relative(news[i].publishedAt),
                  url: assetUrl(news[i].cover) ?? '',
                  onTap: () => onSelectTab?.call(2),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A single featured slide: full-bleed image, dark overlay, "خبر رئيسي" badge,
/// and a bottom-aligned right-aligned title.
class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.url, required this.title, this.onTap});

  final String url;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkImageBox(url: url, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(gradient: AppColors.sliderOverlay),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                context.l10n.homeMainNewsBadge,
                style: AppText.tajawal(
                  size: 13,
                  weight: AppText.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            left: 22,
            bottom: 22,
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: AppText.tajawal(
                size: 25,
                weight: AppText.extraBold,
                color: Colors.white,
                height: 1.45,
              ).copyWith(
                shadows: const [
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single "أحدث الأخبار" row. DOM order is text-then-image, so under RTL the
/// text sits on the RIGHT and the thumbnail on the LEFT (per spec).
class _NewsRow extends StatelessWidget {
  const _NewsRow({
    required this.title,
    required this.time,
    required this.url,
    this.onTap,
  });

  final String title;
  final String time;
  final String url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: 22,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.tajawal(
                    size: 16,
                    weight: AppText.extraBold,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(time, style: AppText.muted),
              ],
            ),
          ),
          const SizedBox(width: 14),
          NetworkImageBox(
            url: url,
            width: 108,
            height: 84,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }
}
