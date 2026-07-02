import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/i18n/locale_provider.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/shared/widgets/governorate_picker.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Create / edit store (`/market/store/edit`). First create auto-assigns the
/// `seller` role. Writes raw `_ar/_en` columns.
class StoreEditScreen extends ConsumerStatefulWidget {
  const StoreEditScreen({super.key});

  @override
  ConsumerState<StoreEditScreen> createState() => _StoreEditScreenState();
}

class _StoreEditScreenState extends ConsumerState<StoreEditScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  Governorate? _gov;

  bool _prefilled = false;
  bool _loading = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit(int? storeId) async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    setState(() => _nameError = name.isEmpty ? context.l10n.sellerStoreNameRequired : null);
    if (name.isEmpty) return;

    // Reads are localized; write name/bio into the column matching the active
    // locale on edit (on create, name_ar is required so always use it).
    final locale = ref.read(localeProvider).languageCode;
    final nameKey = (storeId != null && locale == 'en') ? 'name_en' : 'name_ar';
    final bioKey = (storeId != null && locale == 'en') ? 'bio_en' : 'bio_ar';
    final body = <String, dynamic>{nameKey: name};
    if (_bio.text.trim().isNotEmpty) body[bioKey] = _bio.text.trim();
    if (_phone.text.trim().isNotEmpty) body['phone'] = _phone.text.trim();
    if (_whatsapp.text.trim().isNotEmpty) body['whatsapp'] = _whatsapp.text.trim();
    if (_email.text.trim().isNotEmpty) body['email'] = _email.text.trim();
    if (_city.text.trim().isNotEmpty) body['city'] = _city.text.trim();
    if (_gov != null) body['governorate'] = _gov!.code;

    setState(() => _loading = true);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      storeId == null
          ? await repo.createStore(body)
          : await repo.updateStore(storeId, body);
      ref.invalidate(myStoreProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(storeId == null
                ? context.l10n.sellerStoreCreated
                : context.l10n.savedChanges)));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isValidation) {
        setState(() =>
            _nameError = e.fieldError('name_ar') ?? e.fieldError('name_en'));
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(myStoreProvider).valueOrNull;
    if (store != null && !_prefilled) {
      _prefilled = true;
      _name.text = store.name;
      _bio.text = store.bio ?? '';
      _phone.text = store.phone ?? '';
      _whatsapp.text = store.whatsapp ?? '';
      _email.text = store.email ?? '';
      _city.text = store.city ?? '';
    }
    final isEdit = store != null;

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
                      child: Text(
                          isEdit
                              ? context.l10n.sellerEditStore
                              : context.l10n.sellerCreateStoreButton,
                          style: AppText.screenTitle),
                    ),
                  ),
                  ClayHeaderButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/market/my-store'),
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
                    label: context.l10n.sellerStoreNameLabel,
                    hint: context.l10n.sellerStoreNameHint,
                    errorText: _nameError,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _bio,
                    label: context.l10n.sellerStoreBioLabel,
                    hint: context.l10n.sellerStoreBioHint,
                    maxLength: 2000,
                  ),
                  const SizedBox(height: 18),
                  GovernorateField(
                    value: _gov,
                    onChanged: (g) => setState(() => _gov = g),
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _city,
                    label: context.l10n.sellerCityLabel,
                    hint: context.l10n.sellerCityHint,
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _phone,
                    label: context.l10n.sellerPhoneLabel,
                    hint: '07XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _whatsapp,
                    label: context.l10n.sellerWhatsappLabel,
                    hint: '+9647XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 18),
                  ClayTextField(
                    controller: _email,
                    label: context.l10n.sellerEmailLabel,
                    hint: 'store@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 30),
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LoadingState(),
                        )
                      : Clay3DButton(
                          label: isEdit
                              ? context.l10n.save
                              : context.l10n.sellerCreateStoreSubmit,
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
                          height: 60,
                          radius: 20,
                          onTap: () => _submit(store?.id),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
