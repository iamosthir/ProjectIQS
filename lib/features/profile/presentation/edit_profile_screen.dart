import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/shared/data/reference_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/shared/widgets/entity_picker.dart';
import 'package:iqs_flutter/shared/widgets/governorate_picker.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Edit profile (`/profile/edit`, `PUT /auth/profile`). Partial update — only
/// changed fields are sent. Name/email/gender/dob prefill; governorate prefills
/// best-effort by matching the loaded list. Supported club/team are set via the
/// shared search pickers (the API returns only their ids, so they start unset).
/// Avatar upload is deferred (no mobile media endpoint for it).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  Governorate? _gov;
  bool _govPrefilled = false;
  String? _gender; // 'male' | 'female'
  DateTime? _dob;

  PickerOption? _club;
  bool _clubTouched = false;
  PickerOption? _team;
  bool _teamTouched = false;

  bool _loading = false;
  String? _nameError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user?.name != null) _name.text = user!.name!;
    if (user?.email != null) _email.text = user!.email!;
    _gender = user?.gender;
    _dob = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  /// Best-effort governorate prefill once the list is available.
  void _maybePrefillGov(List<Governorate> list) {
    if (_govPrefilled) return;
    _govPrefilled = true;
    final current = ref.read(currentUserProvider)?.governorate;
    if (current == null || current.isEmpty) return;
    for (final g in list) {
      if (g.name == current || g.code == current) {
        _gov = g;
        break;
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    // Backend rule is `before:today`, so cap at yesterday — today is invalid.
    final yesterday =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: yesterday,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<List<PickerOption>> _searchClubs(String q) async {
    final page =
        await ref.read(clubsRepositoryProvider).clubs(q: q.isEmpty ? null : q);
    return page.items.map((c) => (id: c.id, name: c.name)).toList();
  }

  Future<List<PickerOption>> _searchTeams(String q) async {
    final results =
        await ref.read(discoveryRepositoryProvider).search(q, type: 'team');
    return results.map((r) => (id: r.id, name: r.title)).toList();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? context.l10n.notifNameRequired : null;
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
    // Only send club/team when the user touched them (null clears server-side).
    if (_clubTouched) body['supported_club_id'] = _club?.id;
    if (_teamTouched) body['supported_team_id'] = _team?.id;

    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(context.l10n.savedChanges)));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isValidation) {
        final nameErr = e.fieldError('name');
        final emailErr = e.fieldError('email');
        setState(() {
          _nameError = nameErr;
          _emailError = emailErr;
        });
        // A 422 on an unmapped field (e.g. date_of_birth) would otherwise be
        // swallowed — surface its message so the save failure isn't silent.
        if (nameErr == null && emailErr == null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(e.message)));
        }
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
    // Keep the governorate list warm for prefill + the picker.
    ref.watch(governoratesProvider).whenData(_maybePrefillGov);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              bottomRadius: 36,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Row(
                children: [
                  const SizedBox(width: 50),
                  Expanded(
                    child: Center(
                        child: Text(context.l10n.notifEditProfileTitle,
                            style: AppText.screenTitle)),
                  ),
                  ClayHeaderButton(
                    icon: Icons.chevron_left,
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/more'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClayTextField(
                    controller: _name,
                    label: context.l10n.notifNameLabel,
                    hint: context.l10n.notifNameHint,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _email,
                    label: context.l10n.notifEmailLabel,
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
                  const SizedBox(height: 18),
                  EntityPickerField(
                    value: _club,
                    label: context.l10n.notifFavoriteClubLabel,
                    sheetTitle: context.l10n.notifPickClub,
                    hint: context.l10n.notifPickClub,
                    searchHint: context.l10n.notifSearchClubHint,
                    search: _searchClubs,
                    onChanged: (o) => setState(() {
                      _club = o;
                      _clubTouched = true;
                    }),
                  ),
                  const SizedBox(height: 18),
                  EntityPickerField(
                    value: _team,
                    label: context.l10n.notifFavoriteTeamLabel,
                    sheetTitle: context.l10n.notifPickTeam,
                    hint: context.l10n.notifPickTeam,
                    searchHint: context.l10n.notifSearchTeamHint,
                    searchOnly: true,
                    search: _searchTeams,
                    onChanged: (o) => setState(() {
                      _team = o;
                      _teamTouched = true;
                    }),
                  ),
                  const SizedBox(height: 32),
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LoadingState(),
                        )
                      : Clay3DButton(
                          label: context.l10n.save,
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
          child: Text(context.l10n.notifGenderLabel, style: AppText.groupLabel),
        ),
        Row(
          children: [
            Expanded(child: _genderOption(context.l10n.notifGenderMale, 'male')),
            const SizedBox(width: 12),
            Expanded(
                child: _genderOption(context.l10n.notifGenderFemale, 'female')),
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
          child: Text(context.l10n.notifDobLabel, style: AppText.groupLabel),
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
                            ? context.l10n.notifPickDate
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
