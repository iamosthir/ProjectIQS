import 'dart:async';

import 'package:flutter/material.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'app_states.dart';

/// A picked entity (id + display name).
typedef PickerOption = ({int id, String name});

/// A tappable clay field that opens a searchable picker sheet for a remote
/// entity (clubs, teams, …). Reused by edit-profile. Returns the chosen option
/// or null (cleared) via [onChanged].
class EntityPickerField extends StatelessWidget {
  const EntityPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.search,
    required this.label,
    required this.sheetTitle,
    this.hint,
    this.searchHint,
    this.searchOnly = false,
  });

  final PickerOption? value;
  final ValueChanged<PickerOption?> onChanged;
  final Future<List<PickerOption>> Function(String query) search;
  final String label;
  final String sheetTitle;
  final String? hint;
  final String? searchHint;

  /// When true the sheet shows nothing until the user types (e.g. team search
  /// requires q≥2 server-side).
  final bool searchOnly;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint ?? context.l10n.selectHint;
    final searchHint = this.searchHint ?? context.l10n.searchHint;
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
                final picked = await showModalBottomSheet<PickerOption?>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => _EntityPickerSheet(
                    title: sheetTitle,
                    searchHint: searchHint,
                    search: search,
                    searchOnly: searchOnly,
                    hasValue: value != null,
                  ),
                );
                // The sheet returns:
                //  - a PickerOption → selected
                //  - a sentinel (id:-1) → cleared
                //  - null → dismissed (no change)
                if (picked == null) return;
                onChanged(picked.id == -1 ? null : picked);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value?.name ?? hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _EntityPickerSheet extends StatefulWidget {
  const _EntityPickerSheet({
    required this.title,
    required this.searchHint,
    required this.search,
    required this.searchOnly,
    required this.hasValue,
  });

  final String title;
  final String searchHint;
  final Future<List<PickerOption>> Function(String query) search;
  final bool searchOnly;
  final bool hasValue;

  @override
  State<_EntityPickerSheet> createState() => _EntityPickerSheetState();
}

class _EntityPickerSheetState extends State<_EntityPickerSheet> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<List<PickerOption>>? _future;

  @override
  void initState() {
    super.initState();
    if (!widget.searchOnly) _future = widget.search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final q = _input.text.trim();
      setState(() {
        _query = q;
        _future = (widget.searchOnly && q.length < 2)
            ? Future.value(const <PickerOption>[])
            : widget.search(q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.screenBgWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: Column(
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
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text(widget.title, style: AppText.sectionHeader)),
                if (widget.hasValue)
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, (id: -1, name: '')),
                    child: Text(context.l10n.none,
                        style: AppText.tajawal(
                            size: 14,
                            weight: AppText.bold,
                            color: AppColors.logoutText)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: Clay.card(radius: 16, gradient: AppColors.surface),
              child: TextField(
                controller: _input,
                onChanged: _onChanged,
                autofocus: widget.searchOnly,
                textInputAction: TextInputAction.search,
                style: AppText.tajawal(size: 15, weight: AppText.bold),
                cursorColor: AppColors.primaryGreen,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: widget.searchHint,
                  hintStyle: AppText.muted,
                  icon: const Icon(Icons.search,
                      size: 20, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    if (_future == null) {
      return EmptyState(title: context.l10n.typeToSearch);
    }
    return FutureBuilder<List<PickerOption>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snap.hasError) {
          return appErrorView(snap.error!,
              onRetry: () => setState(() => _future = widget.search(_query)));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return EmptyState(title: context.l10n.noResults);
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, i) {
            final o = items[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context, o),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  child: Text(o.name, style: AppText.rowLabel),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
