import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/i18n/locale_provider.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/clubs/application/clubs_providers.dart';
import 'package:iqs_flutter/features/clubs/data/club.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'admin_form_sheet.dart';
import 'club_admin_specs.dart';

/// News manager (`/my-club/news`) — lists the club's published news; create /
/// edit (fetches the article for full-content prefill) / delete.
class MyClubNewsScreen extends ConsumerStatefulWidget {
  const MyClubNewsScreen({super.key});

  @override
  ConsumerState<MyClubNewsScreen> createState() => _MyClubNewsScreenState();
}

class _MyClubNewsScreenState extends ConsumerState<MyClubNewsScreen> {
  int _reload = 0;

  void _refresh() {
    if (mounted) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myClubProvider);
    final clubId = async.valueOrNull?.id;
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                ClayHeaderButton(
                  icon: Icons.add,
                  onTap: () {
                    if (clubId != null) _openForm(clubId);
                  },
                ),
                Expanded(
                  child: Center(
                      child: Text(context.l10n.clubAdminManageNews,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/my-club'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myClubProvider),
              data: (club) => PaginatedListView<ClubNews>(
                key: ValueKey('mynews-$_reload'),
                loader: (page) =>
                    ref.read(clubsRepositoryProvider).clubNews(club.id, page: page),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                emptyTitle: context.l10n.clubAdminNoNews,
                emptySubtitle: context.l10n.clubAdminAddFirstNews,
                itemBuilder: (context, news, _) => _NewsRow(
                  news: news,
                  onEdit: () => _editNews(club.id, news),
                  onDelete: () => _deleteNews(news),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editNews(int clubId, ClubNews news) async {
    // Fetch the full article so the (required) content field is prefilled.
    ClubNews full;
    try {
      full = await ref
          .read(clubsRepositoryProvider)
          .clubNewsArticle(clubId, news.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
      return;
    }
    if (!mounted) return;
    _openForm(clubId, news: full);
  }

  void _openForm(int clubId, {ClubNews? news}) {
    final ar = ref.read(localeProvider).languageCode != 'en';
    final suffix = ar ? 'ar' : 'en';
    final initial = <String, String>{};
    if (news != null) {
      initial['title_$suffix'] = news.title;
      if (news.excerpt != null) initial['excerpt_$suffix'] = news.excerpt!;
      if (news.content != null) initial['content_$suffix'] = news.content!;
      if (news.authorName != null) initial['author_name'] = news.authorName!;
      initial['is_published'] = 'true';
    }
    showAdminFormSheet(
      context: context,
      title: news == null
          ? context.l10n.clubAdminNewNews
          : context.l10n.clubAdminEditNews,
      fields: clubNewsFields(context.l10n),
      initial: initial,
      // Required only on create; edits are partial (`sometimes`).
      enforceRequired: news == null,
      onSubmit: (body) async {
        try {
          final repo = ref.read(clubsRepositoryProvider);
          news == null
              ? await repo.createClubNews(body)
              : await repo.updateClubNews(news.id, body);
          _refresh();
          return null;
        } on ApiException catch (e) {
          if (e.isValidation && e.errors != null) {
            final invalid = mounted ? context.l10n.clubAdminInvalidValue : '';
            return e.errors!
                .map((k, v) => MapEntry(k, v.isNotEmpty ? v.first : invalid));
          }
          if (mounted) _snack(e.message);
          return const {};
        }
      },
    );
  }

  Future<void> _deleteNews(ClubNews news) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.screenBgWhite,
        title: Text(context.l10n.clubAdminDeleteNews, style: AppText.sectionHeader),
        content: Text(context.l10n.clubAdminDeleteConfirm(news.title),
            style: AppText.muted),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel, style: AppText.muted)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.delete,
                style: AppText.tajawal(
                    size: 14, weight: AppText.bold, color: AppColors.logoutText)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clubsRepositoryProvider).deleteClubNews(news.id);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({
    required this.news,
    required this.onEdit,
    required this.onDelete,
  });

  final ClubNews news;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      onTap: onEdit,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tajawal(
                        size: 15,
                        weight: AppText.bold,
                        color: AppColors.textPrimary,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(DateFmt.relative(news.publishedAt), style: AppText.muted),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.logoutText),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
