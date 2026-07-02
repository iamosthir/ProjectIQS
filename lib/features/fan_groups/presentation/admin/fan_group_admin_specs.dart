import 'package:iqs_flutter/features/clubs/presentation/admin/admin_form.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';

/// Field specs for the fan-group-admin edit form. Bilingual columns are two
/// fields (`*_ar` / `*_en`) per the write API (`PUT /my-fan-group`). Logo/cover
/// uploads are deferred — no mobile upload endpoint — so `*_path` fields are
/// omitted and left untouched on save (`sometimes`). Labels are localized.
List<AdminField> fanGroupProfileFields(AppLocalizations l) => [
      AdminField(key: 'name_ar', label: l.adminNameAr, required: true),
      AdminField(key: 'name_en', label: l.adminNameEn, ltr: true),
      AdminField(
          key: 'description_ar',
          label: l.adminDescriptionAr,
          kind: AdminFieldKind.multiline),
      AdminField(
          key: 'description_en',
          label: l.adminDescriptionEn,
          kind: AdminFieldKind.multiline,
          ltr: true),
      AdminField(key: 'governorate', label: l.governorate),
      AdminField(key: 'city', label: l.adminCity),
      AdminField(
          key: 'founded_year',
          label: l.adminFoundedYear,
          kind: AdminFieldKind.number),
      AdminField(key: 'phone', label: l.adminPhone, ltr: true),
      AdminField(key: 'facebook', label: l.adminFacebook, ltr: true),
      AdminField(key: 'instagram', label: l.adminInstagram, ltr: true),
      AdminField(key: 'twitter', label: l.adminTwitter, ltr: true),
    ];
