import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/shared/widgets/governorate_picker.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';

/// Complete-profile screen (`/register`), shown when `needs_registration`.
/// Name is required; the rest are optional. Supported club/team selection is
/// deferred to edit-profile (Phase 9) when the club/search endpoints are wired.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  Governorate? _gov;
  String? _gender; // 'male' | 'female'
  DateTime? _dob;

  bool _loading = false;
  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Prefill from the user object returned by verify-otp, if any.
    final user = ref.read(authProvider).valueOrNull?.user;
    if (user?.name != null) _name.text = user!.name!;
    if (user?.email != null) _email.text = user!.email!;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? context.l10n.authNameRequired : null;
      _emailError = null;
    });
    if (name.isEmpty) return;

    final body = <String, dynamic>{'name': name};
    final email = _email.text.trim();
    if (email.isNotEmpty) body['email'] = email;
    if (_gov != null) body['governorate'] = _gov!.code;
    if (_gender != null) body['gender'] = _gender;
    if (_dob != null) {
      body['date_of_birth'] = DateFormat('yyyy-MM-dd').format(_dob!);
    }

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).completeRegistration(body);
      // Success → auth state → router redirect to /home.
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isValidation) {
        setState(() {
          _nameError = e.fieldError('name');
          _emailError = e.fieldError('email');
        });
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              bottomRadius: 36,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Center(
                child: Text(context.l10n.authCompleteProfileTitle,
                    style: AppText.screenTitle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.authTellUsMore,
                    style: AppText.tajawal(
                      size: 20,
                      weight: AppText.extraBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClayTextField(
                    controller: _name,
                    label: context.l10n.authNameLabel,
                    hint: context.l10n.authNameHint,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _email,
                    label: context.l10n.authEmailOptionalLabel,
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    errorText: _emailError,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  GovernorateField(
                    value: _gov,
                    onChanged: (g) => setState(() => _gov = g),
                  ),
                  const SizedBox(height: 18),
                  _genderSelector(),
                  const SizedBox(height: 18),
                  _dobField(),
                  const SizedBox(height: 32),
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LoadingState(),
                        )
                      : Clay3DButton(
                          label: context.l10n.authSaveAndContinue,
                          gradient: AppColors.login3d,
                          hardShadow: AppColors.login3dHardShadow,
                          softShadow: [
                            BoxShadow(
                              color: const Color(0xFF19773B)
                                  .withValues(alpha: 0.55),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                              spreadRadius: -6,
                            ),
                          ],
                          height: 62,
                          radius: 20,
                          onTap: _submit,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(context.l10n.authGenderOptionalLabel,
              style: AppText.groupLabel),
        ),
        Row(
          children: [
            Expanded(child: _genderOption(context.l10n.authGenderMale, 'male')),
            const SizedBox(width: 12),
            Expanded(
                child: _genderOption(context.l10n.authGenderFemale, 'female')),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(String label, String value) {
    final active = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: active
            ? BoxDecoration(
                gradient: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green1D8040.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ],
              )
            : Clay.card(radius: 16, gradient: AppColors.surface),
        child: Text(
          label,
          style: AppText.tajawal(
            size: 15,
            weight: AppText.bold,
            color: active ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _dobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(context.l10n.authDobOptionalLabel,
              style: AppText.groupLabel),
        ),
        Container(
          decoration: Clay.card(radius: 18, gradient: AppColors.surface),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickDob,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dob == null
                            ? context.l10n.authSelectDate
                            : DateFormat('d MMMM y', 'ar').format(_dob!),
                        style: AppText.tajawal(
                          size: 16,
                          weight: AppText.bold,
                          color: _dob == null
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
