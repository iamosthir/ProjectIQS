import 'package:flutter/material.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'admin_form.dart';

/// Opens an [AdminFormBody] in a scrollable modal sheet. [onSubmit] returns
/// field errors on failure, or null on success (the sheet then closes).
Future<void> showAdminFormSheet({
  required BuildContext context,
  required String title,
  required List<AdminField> fields,
  required Map<String, String> initial,
  required Future<Map<String, String>?> Function(Map<String, dynamic> body)
      onSubmit,
  bool enforceRequired = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
        decoration: const BoxDecoration(
          color: AppColors.screenBgWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(title, style: AppText.sectionHeader)),
              const SizedBox(height: 18),
              AdminFormBody(
                fields: fields,
                initial: initial,
                submitLabel: context.l10n.save,
                enforceRequired: enforceRequired,
                onSubmit: (body) async {
                  final errors = await onSubmit(body);
                  if (errors == null && ctx.mounted) Navigator.of(ctx).pop();
                  return errors;
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
