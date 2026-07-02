import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';

enum AdminFieldKind { text, multiline, number, select, toggle }

/// One field in a [AdminFormBody]. Bilingual columns are modelled as two
/// separate fields (e.g. `name_ar`, `name_en`), matching the write API.
class AdminField {
  const AdminField({
    required this.key,
    required this.label,
    this.kind = AdminFieldKind.text,
    this.required = false,
    this.options = const [],
    this.ltr = false,
  });

  final String key;
  final String label;
  final AdminFieldKind kind;
  final bool required;
  final List<(String label, String value)> options; // for select
  final bool ltr;
}

/// A generic form driven by [fields]. Returns a body map keyed by field key;
/// numbers parse to int, toggles to bool. [onSubmit] returns field errors on
/// failure or null on success (the caller navigates away).
class AdminFormBody extends StatefulWidget {
  const AdminFormBody({
    super.key,
    required this.fields,
    required this.initial,
    required this.submitLabel,
    required this.onSubmit,
    this.enforceRequired = true,
  });

  final List<AdminField> fields;
  final Map<String, String> initial;
  final String submitLabel;
  final Future<Map<String, String>?> Function(Map<String, dynamic> body)
      onSubmit;

  /// On EDIT this is false: the backend uses `sometimes` rules, so an empty
  /// (non-prefilled opposite-locale) column must NOT block a partial update.
  final bool enforceRequired;

  @override
  State<AdminFormBody> createState() => _AdminFormBodyState();
}

class _AdminFormBodyState extends State<AdminFormBody> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _selects = {};
  final Map<String, bool> _toggles = {};
  final Map<String, String?> _errors = {};
  String? _generalError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final init = widget.initial[f.key];
      switch (f.kind) {
        case AdminFieldKind.select:
          _selects[f.key] = init;
        case AdminFieldKind.toggle:
          _toggles[f.key] = init == 'true' || init == '1';
        default:
          _controllers[f.key] = TextEditingController(text: init ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    _errors.clear();
    final body = <String, dynamic>{};
    var hasError = false;
    for (final f in widget.fields) {
      switch (f.kind) {
        case AdminFieldKind.toggle:
          body[f.key] = _toggles[f.key] ?? false;
        case AdminFieldKind.select:
          final v = _selects[f.key];
          if (f.required && widget.enforceRequired && (v == null || v.isEmpty)) {
            _errors[f.key] = l10n.required;
            hasError = true;
          } else if (v != null && v.isNotEmpty) {
            body[f.key] = v;
          }
        case AdminFieldKind.number:
          final t = _controllers[f.key]!.text.trim();
          if (t.isEmpty) {
            if (f.required && widget.enforceRequired) {
              _errors[f.key] = l10n.required;
              hasError = true;
            }
          } else {
            final n = int.tryParse(t);
            if (n == null) {
              _errors[f.key] = l10n.invalidNumber;
              hasError = true;
            } else {
              body[f.key] = n;
            }
          }
        default:
          final t = _controllers[f.key]!.text.trim();
          if (t.isEmpty) {
            if (f.required && widget.enforceRequired) {
              _errors[f.key] = l10n.required;
              hasError = true;
            }
          } else {
            body[f.key] = t;
          }
      }
    }
    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _loading = true);
    final errors = await widget.onSubmit(body);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _generalError = null;
      if (errors != null) {
        _errors
          ..clear()
          ..addAll(errors);
        // Surface any 422 errors whose key has no rendered field (nested/renamed
        // keys) so the failure isn't silent.
        final fieldKeys = widget.fields.map((f) => f.key).toSet();
        final unmatched = errors.entries
            .where((e) => !fieldKeys.contains(e.key) && e.value.isNotEmpty)
            .map((e) => e.value)
            .toList();
        if (unmatched.isNotEmpty) _generalError = unmatched.join('\n');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in widget.fields) ...[
          _field(f),
          const SizedBox(height: 16),
        ],
        if (_generalError != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _generalError!,
              textAlign: TextAlign.center,
              style: AppText.tajawal(
                  size: 13,
                  weight: AppText.medium,
                  color: AppColors.logoutText),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LoadingState(),
              )
            : GreenPillButton(label: widget.submitLabel, onTap: _submit),
      ],
    );
  }

  Widget _field(AdminField f) {
    switch (f.kind) {
      case AdminFieldKind.toggle:
        return _toggleField(f);
      case AdminFieldKind.select:
        return _selectField(f);
      case AdminFieldKind.multiline:
        return ClayTextField(
          controller: _controllers[f.key]!,
          label: f.label,
          errorText: _errors[f.key],
          maxLength: 4000,
        );
      case AdminFieldKind.number:
        return ClayTextField(
          controller: _controllers[f.key]!,
          label: f.label,
          errorText: _errors[f.key],
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))],
        );
      default:
        return ClayTextField(
          controller: _controllers[f.key]!,
          label: f.label,
          errorText: _errors[f.key],
          textDirection: f.ltr ? TextDirection.ltr : null,
          textAlign: f.ltr ? TextAlign.left : null,
          onChanged: (_) {
            if (_errors[f.key] != null) setState(() => _errors[f.key] = null);
          },
        );
    }
  }

  Widget _selectField(AdminField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(f.label, style: AppText.groupLabel),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in f.options)
              AppChip(
                label: o.$1,
                active: _selects[f.key] == o.$2,
                onTap: () => setState(() {
                  _selects[f.key] = o.$2;
                  _errors[f.key] = null;
                }),
              ),
          ],
        ),
        if (_errors[f.key] != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(_errors[f.key]!,
                style: AppText.tajawal(
                    size: 12,
                    weight: AppText.medium,
                    color: AppColors.logoutText)),
          ),
        ],
      ],
    );
  }

  Widget _toggleField(AdminField f) {
    final on = _toggles[f.key] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _toggles[f.key] = !on),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: Clay.card(radius: 16, gradient: AppColors.surface),
        child: Row(
          children: [
            Icon(
              on
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: on ? AppColors.primaryGreen : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(f.label, style: AppText.rowLabel)),
          ],
        ),
      ),
    );
  }
}
