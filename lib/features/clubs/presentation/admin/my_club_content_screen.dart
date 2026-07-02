import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/i18n/locale_provider.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/clubs/application/clubs_providers.dart';
import 'package:iqs_flutter/features/clubs/data/club_detail.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'admin_form_sheet.dart';
import 'club_admin_specs.dart';

typedef _Item = ({int id, String title, String? subtitle, Map<String, String> initial});

/// Generic content manager for a club child type (`/my-club/content/:type`).
/// Lists items from the my-club detail and creates/edits/deletes via modal forms.
class MyClubContentScreen extends ConsumerWidget {
  const MyClubContentScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClubProvider);
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
                  onTap: () => _openForm(context, ref),
                ),
                Expanded(
                  child: Center(
                      child:
                          Text(childTypeLabel(type, context.l10n),
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
              data: (club) {
                final locale = ref.read(localeProvider).languageCode;
                final items = _items(club, locale);
                if (items.isEmpty) {
                  return EmptyState(
                    title: context.l10n.clubAdminNoItems,
                    subtitle: context.l10n.clubAdminAddFirstItem,
                    onRetry: () => _openForm(context, ref),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _row(context, ref, items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, _Item item) {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      onTap: () => _openForm(context, ref, item: item),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.rowLabel),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.subtitle!, style: AppText.muted),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.logoutText),
            onPressed: () => _delete(context, ref, item),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref, {_Item? item}) {
    showAdminFormSheet(
      context: context,
      title: item == null ? context.l10n.add : context.l10n.edit,
      fields: childFields(type, context.l10n),
      initial: item?.initial ?? const {},
      // Required only on create; edits are partial (`sometimes`).
      enforceRequired: item == null,
      onSubmit: (body) async {
        try {
          final repo = ref.read(clubsRepositoryProvider);
          item == null
              ? await repo.createChild(type, body)
              : await repo.updateChild(type, item.id, body);
          if (!context.mounted) return null;
          ref.invalidate(myClubProvider);
          return null;
        } on ApiException catch (e) {
          if (e.isValidation && e.errors != null) {
            final invalid =
                context.mounted ? context.l10n.clubAdminInvalidValue : '';
            return e.errors!
                .map((k, v) => MapEntry(k, v.isNotEmpty ? v.first : invalid));
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(e.message)));
          }
          return const {};
        }
      },
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, _Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.screenBgWhite,
        title: Text(context.l10n.delete, style: AppText.sectionHeader),
        content: Text(context.l10n.clubAdminDeleteConfirm(item.title),
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
      await ref.read(clubsRepositoryProvider).deleteChild(type, item.id);
      if (!context.mounted) return;
      ref.invalidate(myClubProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // Maps a club's child collection for [type] to generic list items, with
  // locale-matched bilingual prefill (the read value goes into the active
  // locale's column).
  List<_Item> _items(ClubDetail club, String locale) {
    final ar = locale != 'en';
    Map<String, String> bi(String base, String? value) =>
        {'${base}_${ar ? 'ar' : 'en'}': value ?? ''};

    switch (type) {
      case 'board':
        return [
          for (final m in club.board)
            (
              id: m.id,
              title: m.name,
              subtitle: m.position,
              initial: {
                ...bi('name', m.name),
                ...bi('position', m.position),
                'parent_id': m.parentId?.toString() ?? '',
                'display_order': m.displayOrder.toString(),
              },
            ),
        ];
      case 'staff':
        return [
          for (final s in club.staff)
            (
              id: s.id,
              title: s.name,
              subtitle: s.role,
              initial: {
                ...bi('name', s.name),
                ...bi('role', s.role),
                'type': s.type ?? '',
                'bio': s.bio ?? '',
              },
            ),
        ];
      case 'titles':
        return [
          for (final t in club.titles)
            (
              id: t.id,
              title: t.title,
              subtitle: [t.competition, t.season].whereType<String>().join(' · '),
              initial: {
                ...bi('title', t.title),
                ...bi('competition', t.competition),
                'season': t.season ?? '',
                'year': t.year?.toString() ?? '',
                'count': t.count.toString(),
              },
            ),
        ];
      case 'captains':
        return [
          for (final c in club.captains)
            (
              id: c.id,
              title: c.name,
              subtitle:
                  [c.periodFrom, c.periodTo].whereType<String>().join(' – '),
              initial: {
                ...bi('name', c.name),
                'period_from': c.periodFrom ?? '',
                'period_to': c.periodTo ?? '',
                'description': c.description ?? '',
              },
            ),
        ];
      case 'competitions':
        return [
          for (final c in club.competitions)
            (
              id: c.id,
              title: c.name,
              subtitle: [c.season, c.status].whereType<String>().join(' · '),
              initial: {
                ...bi('name', c.name),
                'season': c.season ?? '',
                'status': c.status ?? '',
                'league_id': c.leagueId?.toString() ?? '',
              },
            ),
        ];
      default:
        return const [];
    }
  }
}
