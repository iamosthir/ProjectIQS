import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';

/// Fan-group verification-request sheet. 403 when the feature flag is off.
class FanGroupVerifySheet extends ConsumerStatefulWidget {
  const FanGroupVerifySheet({super.key, required this.fanGroupId});

  final int fanGroupId;

  @override
  ConsumerState<FanGroupVerifySheet> createState() =>
      _FanGroupVerifySheetState();
}

class _FanGroupVerifySheetState extends ConsumerState<FanGroupVerifySheet> {
  String _method = 'message';
  final _note = TextEditingController();
  bool _loading = false;

  List<(String, String)> _methodOptions(BuildContext context) => [
        (context.l10n.fanGroupsMethodMessage, 'message'),
        (context.l10n.fanGroupsMethodVoice, 'voice'),
        (context.l10n.fanGroupsMethodVideo, 'video'),
      ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(fanGroupsRepositoryProvider).verifyRequest(
            widget.fanGroupId,
            method: _method,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      final sent = context.l10n.fanGroupsVerifySent;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(sent)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final methods = _methodOptions(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.screenBgWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
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
              Center(child: Text(context.l10n.fanGroupsVerifyTitle, style: AppText.sectionHeader)),
              const SizedBox(height: 18),
              Text(context.l10n.fanGroupsVerifyMethodLabel, style: AppText.groupLabel),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (int i = 0; i < methods.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: AppChip(
                        label: methods[i].$1,
                        active: _method == methods[i].$2,
                        onTap: () => setState(() => _method = methods[i].$2),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              ClayTextField(
                controller: _note,
                label: context.l10n.fanGroupsVerifyNoteLabel,
                hint: context.l10n.fanGroupsVerifyNoteHint,
                maxLength: 1000,
              ),
              const SizedBox(height: 22),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LoadingState(),
                    )
                  : GreenPillButton(label: context.l10n.fanGroupsVerifySubmit, onTap: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
