import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/shared/data/reference_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'app_states.dart';

/// A tappable field that shows the selected governorate and opens a searchable
/// picker sheet. Reused by register, edit-profile, listings and filters.
class GovernorateField extends StatelessWidget {
  const GovernorateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
  });

  final Governorate? value;
  final ValueChanged<Governorate> onChanged;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final label = this.label ?? context.l10n.governorate;
    final hint = this.hint ?? context.l10n.selectGovernorate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(label, style: AppText.groupLabel),
        ),
        Container(
          decoration: Clay.card(radius: 18, gradient: AppColors.surface),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final picked = await showGovernoratePicker(context);
                if (picked != null) onChanged(picked);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 20, color: AppColors.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value?.name ?? hint,
                        style: AppText.tajawal(
                          size: 16,
                          weight: AppText.bold,
                          color: value == null
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded,
                        size: 22, color: AppColors.chevron),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the searchable governorate picker as a bottom sheet.
Future<Governorate?> showGovernoratePicker(BuildContext context) {
  return showModalBottomSheet<Governorate>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _GovernoratePickerSheet(),
  );
}

class _GovernoratePickerSheet extends ConsumerStatefulWidget {
  const _GovernoratePickerSheet();

  @override
  ConsumerState<_GovernoratePickerSheet> createState() =>
      _GovernoratePickerSheetState();
}

class _GovernoratePickerSheetState
    extends ConsumerState<_GovernoratePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(governoratesProvider);
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.8),
        decoration: const BoxDecoration(
          color: AppColors.screenBgWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.selectGovernorate, style: AppText.sectionHeader),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: Clay.card(radius: 16, gradient: AppColors.surface),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: AppText.tajawal(size: 15, weight: AppText.bold),
                cursorColor: AppColors.primaryGreen,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: context.l10n.searchShort,
                  hintStyle: AppText.muted,
                  icon: const Icon(Icons.search,
                      size: 20, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: LoadingState(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: appErrorView(
                    e,
                    onRetry: () => ref.invalidate(governoratesProvider),
                  ),
                ),
                data: (list) {
                  final filtered = _query.isEmpty
                      ? list
                      : list
                          .where((g) => g.name.contains(_query))
                          .toList();
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(title: context.l10n.noResults),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(
                        color: AppColors.divider, height: 1),
                    itemBuilder: (context, i) {
                      final g = filtered[i];
                      return ListTile(
                        title: Text(g.name, style: AppText.rowLabel),
                        trailing: const Icon(Icons.chevron_left,
                            color: AppColors.chevron),
                        onTap: () => Navigator.of(context).pop(g),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
