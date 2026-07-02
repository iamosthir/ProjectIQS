import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'admin_archive_widgets.dart';

/// Documents manager (`/my-fan-group/documents`). List + delete; documents come
/// from the group detail's `documents[]`. (Adding needs a web file upload.)
class MyFanGroupDocumentsScreen extends ConsumerWidget {
  const MyFanGroupDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFanGroupProvider);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(
                  child: Center(
                      child: Text(context.l10n.fanAdminManageDocuments,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/my-fan-group'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myFanGroupProvider),
              data: (group) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  archiveAddNote(context.l10n.fanAdminDocumentsAddNote),
                  if (group.documents.isEmpty)
                    SizedBox(
                        height: 220,
                        child: EmptyState(
                            title: context.l10n.fanAdminNoDocuments))
                  else
                    for (final d in group.documents) ...[
                      _DocRow(doc: d, onDelete: () => _delete(context, ref, d)),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FanGroupDocument d) async {
    if (!await confirmArchiveDelete(context, d.title)) return;
    try {
      await ref.read(fanGroupsRepositoryProvider).deleteDocument(d.id);
      if (!context.mounted) return;
      ref.invalidate(myFanGroupProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.doc, required this.onDelete});
  final FanGroupDocument doc;
  final VoidCallback onDelete;

  Future<void> _open() async {
    final url = assetUrl(doc.url);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {/* ignore */}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      onTap: _open,
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              size: 22, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.rowLabel),
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
