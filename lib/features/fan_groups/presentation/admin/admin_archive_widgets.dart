import 'package:flutter/material.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';

/// Shared chrome for the fan-group archive managers (media/chants/documents).
/// They support list + delete; *adding* new items needs a file upload the
/// mobile API doesn't expose (the store endpoints take a pre-uploaded `path`),
/// so this note tells the admin where to add — keeping the UI honest (no fake
/// "+" that can't work).
Widget archiveAddNote(String message) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    decoration: Clay.card(radius: 16, gradient: AppColors.surface),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: AppText.tajawal(
                  size: 12.5,
                  weight: AppText.medium,
                  color: AppColors.textMuted,
                  height: 1.5)),
        ),
      ],
    ),
  );
}

/// Confirmation dialog for an archive delete. Returns true when confirmed.
Future<bool> confirmArchiveDelete(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.screenBgWhite,
      title: Text(context.l10n.fanAdminConfirmDeleteTitle,
          style: AppText.sectionHeader),
      content:
          Text(context.l10n.fanAdminConfirmDeleteBody(name), style: AppText.muted),
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
  return ok == true;
}
