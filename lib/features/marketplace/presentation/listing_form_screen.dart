import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:iqs_flutter/core/i18n/locale_provider.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/marketplace/application/marketplace_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/listing.dart';
import 'package:iqs_flutter/features/marketplace/data/marketplace_category.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';
import 'package:iqs_flutter/shared/widgets/app_chip.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/shared/widgets/governorate_picker.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Create (`/market/listings/new`) or edit (`/market/listings/:id/edit`) a
/// listing. Attribute fields are generated from the chosen category's
/// `field_schema`. Free category → `pending_review`; paid → `pending_payment`.
class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({super.key, this.listingId});

  final int? listingId;

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _title = TextEditingController();
  final _fullName = TextEditingController();
  final _nationality = TextEditingController();
  final _city = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactWhatsapp = TextEditingController();
  final _contactEmail = TextEditingController();
  final Map<String, TextEditingController> _attrs = {};
  final Map<String, String?> _attrErrors = {};

  Governorate? _gov;
  DateTime? _dob;
  bool _showContact = true;

  // The selected category id/name (always set on edit, even when the full
  // category object isn't in the leaf tree), and the attribute fields to render.
  int? _categoryId;
  String? _categoryName;
  MarketplaceCategory? _category;
  List<CategoryField> _fields = const [];

  bool _prefilled = false;
  bool _loading = false;
  String? _titleError;

  bool get _isEdit => widget.listingId != null;

  @override
  void dispose() {
    _title.dispose();
    _fullName.dispose();
    _nationality.dispose();
    _city.dispose();
    _contactPhone.dispose();
    _contactWhatsapp.dispose();
    _contactEmail.dispose();
    for (final c in _attrs.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuildAttrs(List<CategoryField> fields, {Listing? prefillFrom}) {
    for (final c in _attrs.values) {
      c.dispose();
    }
    _attrs.clear();
    _attrErrors.clear();
    _fields = fields;
    for (final f in fields) {
      final ctrl = TextEditingController();
      if (prefillFrom != null) {
        for (final a in prefillFrom.attributes) {
          if (a.label == f.key) {
            ctrl.text = a.value;
            break;
          }
        }
      }
      _attrs[f.key] = ctrl;
    }
  }

  void _selectCategory(MarketplaceCategory cat) {
    setState(() {
      _category = cat;
      _categoryId = cat.id;
      _categoryName = cat.name;
      _rebuildAttrs(cat.fieldSchema?.fields ?? const []);
    });
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (!mounted || picked == null) return;
    setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final catId = _categoryId;
    final title = _title.text.trim();
    setState(() => _titleError = title.isEmpty ? context.l10n.sellerTitleRequired : null);
    if (catId == null) {
      _snack(context.l10n.sellerSelectCategoryFirst);
      return;
    }
    // Client-side required-attribute validation (server also enforces).
    var hasAttrError = false;
    for (final f in _fields) {
      if (f.required && (_attrs[f.key]?.text.trim().isEmpty ?? true)) {
        _attrErrors[f.key] = context.l10n.sellerFieldRequired;
        hasAttrError = true;
      }
    }
    if (title.isEmpty || hasAttrError) {
      setState(() {});
      return;
    }

    final attributes = <String, dynamic>{};
    _attrs.forEach((k, c) {
      if (c.text.trim().isNotEmpty) attributes[k] = c.text.trim();
    });

    // Reads are localized; write the title into the column matching the active
    // locale on edit (on create, title_ar is required so always use it).
    final locale = ref.read(localeProvider).languageCode;
    final titleKey = (_isEdit && locale == 'en') ? 'title_en' : 'title_ar';

    final body = <String, dynamic>{
      'category_id': catId,
      titleKey: title,
      'show_contact': _showContact,
      if (attributes.isNotEmpty) 'attributes': attributes,
    };
    if (_fullName.text.trim().isNotEmpty) body['full_name'] = _fullName.text.trim();
    if (_nationality.text.trim().isNotEmpty) {
      body['nationality'] = _nationality.text.trim();
    }
    if (_city.text.trim().isNotEmpty) body['city'] = _city.text.trim();
    if (_gov != null) body['governorate'] = _gov!.code;
    if (_dob != null) body['date_of_birth'] = DateFormat('yyyy-MM-dd').format(_dob!);
    if (_contactPhone.text.trim().isNotEmpty) {
      body['contact_phone'] = _contactPhone.text.trim();
    }
    if (_contactWhatsapp.text.trim().isNotEmpty) {
      body['contact_whatsapp'] = _contactWhatsapp.text.trim();
    }
    if (_contactEmail.text.trim().isNotEmpty) {
      body['contact_email'] = _contactEmail.text.trim();
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      final result = _isEdit
          ? await repo.updateListing(widget.listingId!, body)
          : await repo.createListing(body);
      ref.invalidate(myStoreProvider);
      if (_isEdit) ref.invalidate(listingDetailProvider(widget.listingId!));
      if (!mounted) return;
      // A newly-created paid listing goes straight to checkout; the picker
      // replaces this form so Back returns to the listings origin.
      if (!_isEdit && result.status == ListingStatus.pendingPayment) {
        _snack(context.l10n.sellerCreatedCompletePayment);
        context.pushReplacement('/pay/listing/${result.id}');
        return;
      }
      final msg = result.status == ListingStatus.pendingPayment
          ? context.l10n.sellerSavedAwaitingPayment
          : context.l10n.sellerSavedUnderReview;
      _snack(msg);
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isValidation) {
        setState(() {
          _titleError = e.fieldError('title_ar') ?? e.fieldError('title_en');
          for (final f in _fields) {
            _attrErrors[f.key] = e.fieldError('attributes.${f.key}');
          }
        });
      }
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);
    final listingAsync =
        _isEdit ? ref.watch(listingDetailProvider(widget.listingId!)) : null;

    Widget body;
    if (catsAsync.isLoading || (listingAsync?.isLoading ?? false)) {
      body = const LoadingState();
    } else if (catsAsync.hasError) {
      body = appErrorView(catsAsync.error!,
          onRetry: () => ref.invalidate(categoriesProvider));
    } else if (listingAsync?.hasError ?? false) {
      body = appErrorView(listingAsync!.error!,
          onRetry: () => ref.invalidate(listingDetailProvider(widget.listingId!)));
    } else {
      final leaves = flattenLeafCategories(catsAsync.value!);
      if (_isEdit && !_prefilled && (listingAsync?.hasValue ?? false)) {
        _prefill(listingAsync!.value!, leaves);
      }
      body = _form(leaves);
    }

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
                    child: Text(
                        _isEdit
                            ? context.l10n.sellerEditListingTitle
                            : context.l10n.sellerNewListingTitle,
                        style: AppText.screenTitle),
                  ),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/market/my-listings'),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  void _prefill(Listing l, List<MarketplaceCategory> leaves) {
    _prefilled = true;
    _title.text = l.title;
    _fullName.text = l.fullName ?? '';
    _nationality.text = l.nationality ?? '';
    _city.text = l.city ?? '';
    _categoryId = l.category?.id;
    _categoryName = l.category?.name;
    MarketplaceCategory? cat;
    for (final c in leaves) {
      if (c.id == l.category?.id) {
        cat = c;
        break;
      }
    }
    if (cat != null) {
      _category = cat;
      _rebuildAttrs(cat.fieldSchema?.fields ?? const [], prefillFrom: l);
    } else {
      // Category isn't a known leaf — keep editing working by synthesizing
      // attribute fields from the listing's existing attributes.
      _rebuildAttrs(
        [
          for (final a in l.attributes)
            CategoryField(key: a.label, type: 'text'),
        ],
        prefillFrom: l,
      );
    }
  }

  Widget _form(List<MarketplaceCategory> leaves) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: Text(context.l10n.sellerCategory, style: AppText.groupLabel),
          ),
          if (_isEdit)
            _fixedCategory()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in leaves)
                  AppChip(
                    label: c.name,
                    active: _categoryId == c.id,
                    onTap: () => _selectCategory(c),
                  ),
              ],
            ),
          if (_category?.isPaid ?? false) ...[
            const SizedBox(height: 10),
            _paidNote(_category!),
          ],
          const SizedBox(height: 18),
          ClayTextField(
            controller: _title,
            label: context.l10n.sellerTitleLabel,
            hint: context.l10n.sellerTitleHint,
            errorText: _titleError,
            onChanged: (_) {
              if (_titleError != null) setState(() => _titleError = null);
            },
          ),
          const SizedBox(height: 18),
          ClayTextField(controller: _fullName, label: context.l10n.sellerFullNameLabel),
          const SizedBox(height: 18),
          _dobField(),
          const SizedBox(height: 18),
          ClayTextField(controller: _nationality, label: context.l10n.sellerNationalityLabel),
          const SizedBox(height: 18),
          GovernorateField(
            value: _gov,
            onChanged: (g) => setState(() => _gov = g),
          ),
          const SizedBox(height: 18),
          ClayTextField(controller: _city, label: context.l10n.sellerCityLabel),
          if (_fields.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(context.l10n.sellerAdditionalDetails, style: AppText.sectionHeader),
            for (final f in _fields) ...[
              const SizedBox(height: 16),
              ClayTextField(
                controller: _attrs[f.key]!,
                label: f.label('ar') + (f.required ? ' *' : ''),
                errorText: _attrErrors[f.key],
                onChanged: (_) {
                  if (_attrErrors[f.key] != null) {
                    setState(() => _attrErrors[f.key] = null);
                  }
                },
              ),
            ],
          ],
          const SizedBox(height: 24),
          Text(context.l10n.sellerContactSection, style: AppText.sectionHeader),
          const SizedBox(height: 16),
          ClayTextField(
            controller: _contactPhone,
            label: context.l10n.sellerContactPhone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ClayTextField(
            controller: _contactWhatsapp,
            label: context.l10n.sellerContactWhatsapp,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          ClayTextField(
            controller: _contactEmail,
            label: context.l10n.sellerContactEmail,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _showContactToggle(),
          const SizedBox(height: 30),
          _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LoadingState(),
                )
              : Clay3DButton(
                  label: _isEdit
                      ? context.l10n.sellerSaveEdits
                      : context.l10n.sellerPublishListing,
                  gradient: AppColors.login3d,
                  hardShadow: AppColors.login3dHardShadow,
                  softShadow: [
                    BoxShadow(
                      color: const Color(0xFF19773B).withValues(alpha: 0.55),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                      spreadRadius: -6,
                    ),
                  ],
                  height: 60,
                  radius: 20,
                  onTap: _submit,
                ),
        ],
      ),
    );
  }

  Widget _fixedCategory() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: Clay.card(radius: 16, gradient: AppColors.surface),
      child: Row(
        children: [
          const Icon(Icons.category_outlined,
              size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Text(_categoryName ?? '—', style: AppText.rowLabel),
        ],
      ),
    );
  }

  Widget _paidNote(MarketplaceCategory cat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pillBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.sellerPaidCategoryNote(cat.basePrice, cat.currency),
              style: AppText.tajawal(
                size: 12,
                weight: AppText.medium,
                color: AppColors.pillText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(context.l10n.sellerDobLabel, style: AppText.groupLabel),
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
                            ? context.l10n.sellerPickDate
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

  Widget _showContactToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showContact = !_showContact),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: Clay.card(radius: 16, gradient: AppColors.surface),
        child: Row(
          children: [
            Icon(
              _showContact
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: _showContact ? AppColors.primaryGreen : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(context.l10n.sellerShowContactToBuyers,
                  style: AppText.rowLabel),
            ),
          ],
        ),
      ),
    );
  }
}
