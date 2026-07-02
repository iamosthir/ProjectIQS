import 'package:iqs_flutter/shared/l10n/app_localizations.dart';

import 'admin_form.dart';

/// Field specs for the club-admin forms. Bilingual columns are two fields
/// (`*_ar` / `*_en`) per the write API. (Photo/cover uploads are deferred.)
/// Labels are localized, so the specs are functions taking [AppLocalizations].

List<AdminField> clubProfileFields(AppLocalizations l) => [
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
      AdminField(key: 'address', label: l.adminAddress),
      AdminField(
          key: 'founded_year',
          label: l.adminFoundedYear,
          kind: AdminFieldKind.number),
      AdminField(key: 'phone', label: l.adminPhone, ltr: true),
      AdminField(key: 'email', label: l.adminEmail, ltr: true),
      AdminField(key: 'website', label: l.adminWebsite, ltr: true),
      AdminField(key: 'facebook', label: l.adminFacebook, ltr: true),
      AdminField(key: 'instagram', label: l.adminInstagram, ltr: true),
      AdminField(key: 'twitter', label: l.adminTwitter, ltr: true),
    ];

List<AdminField> clubNewsFields(AppLocalizations l) => [
      AdminField(key: 'title_ar', label: l.adminTitleAr, required: true),
      AdminField(key: 'title_en', label: l.adminTitleEn, ltr: true),
      AdminField(
          key: 'excerpt_ar',
          label: l.adminExcerptAr,
          kind: AdminFieldKind.multiline),
      AdminField(
          key: 'excerpt_en',
          label: l.adminExcerptEn,
          kind: AdminFieldKind.multiline,
          ltr: true),
      AdminField(
          key: 'content_ar',
          label: l.adminContentAr,
          kind: AdminFieldKind.multiline,
          required: true),
      AdminField(
          key: 'content_en',
          label: l.adminContentEn,
          kind: AdminFieldKind.multiline,
          ltr: true),
      AdminField(key: 'author_name', label: l.adminAuthorName),
      AdminField(
          key: 'is_published',
          label: l.adminPublished,
          kind: AdminFieldKind.toggle),
    ];

List<(String, String)> _staffTypes(AppLocalizations l) => [
      (l.adminStaffCoaching, 'coaching'),
      (l.adminStaffTechnical, 'technical'),
      (l.adminStaffMedical, 'medical'),
      (l.adminStaffAdmin, 'admin'),
    ];

List<(String, String)> _competitionStatus(AppLocalizations l) => [
      (l.adminCompActive, 'active'),
      (l.adminCompPast, 'past'),
    ];

/// Localized label for a child type.
String childTypeLabel(String type, AppLocalizations l) {
  switch (type) {
    case 'board':
      return l.adminChildBoard;
    case 'staff':
      return l.adminChildStaff;
    case 'titles':
      return l.adminChildTitles;
    case 'captains':
      return l.adminChildCaptains;
    case 'competitions':
      return l.adminChildCompetitions;
    default:
      return type;
  }
}

/// Form fields for a child type.
List<AdminField> childFields(String type, AppLocalizations l) {
  switch (type) {
    case 'board':
      return [
        AdminField(key: 'name_ar', label: l.adminNameAr, required: true),
        AdminField(
            key: 'name_en', label: l.adminNameEn, required: true, ltr: true),
        AdminField(
            key: 'position_ar', label: l.adminPositionAr, required: true),
        AdminField(
            key: 'position_en',
            label: l.adminPositionEn,
            required: true,
            ltr: true),
        AdminField(
            key: 'parent_id',
            label: l.adminParentIdOptional,
            kind: AdminFieldKind.number),
        AdminField(
            key: 'display_order',
            label: l.adminDisplayOrder,
            kind: AdminFieldKind.number),
      ];
    case 'staff':
      return [
        AdminField(key: 'name_ar', label: l.adminNameAr, required: true),
        AdminField(
            key: 'name_en', label: l.adminNameEn, required: true, ltr: true),
        AdminField(key: 'role_ar', label: l.adminRoleAr, required: true),
        AdminField(
            key: 'role_en', label: l.adminRoleEn, required: true, ltr: true),
        AdminField(
            key: 'type',
            label: l.adminType,
            kind: AdminFieldKind.select,
            required: true,
            options: _staffTypes(l)),
        AdminField(
            key: 'bio', label: l.adminBio, kind: AdminFieldKind.multiline),
        AdminField(
            key: 'display_order',
            label: l.adminDisplayOrder,
            kind: AdminFieldKind.number),
      ];
    case 'titles':
      return [
        AdminField(key: 'title_ar', label: l.adminHonorTitleAr, required: true),
        AdminField(
            key: 'title_en',
            label: l.adminHonorTitleEn,
            required: true,
            ltr: true),
        AdminField(key: 'competition_ar', label: l.adminCompetitionAr),
        AdminField(
            key: 'competition_en', label: l.adminCompetitionEn, ltr: true),
        AdminField(key: 'season', label: l.adminSeason),
        AdminField(
            key: 'year', label: l.adminYear, kind: AdminFieldKind.number),
        AdminField(
            key: 'count', label: l.adminCount, kind: AdminFieldKind.number),
        AdminField(
            key: 'display_order',
            label: l.adminDisplayOrder,
            kind: AdminFieldKind.number),
      ];
    case 'captains':
      return [
        AdminField(key: 'name_ar', label: l.adminNameAr, required: true),
        AdminField(
            key: 'name_en', label: l.adminNameEn, required: true, ltr: true),
        AdminField(
            key: 'period_from',
            label: l.adminPeriodFrom,
            kind: AdminFieldKind.number),
        AdminField(
            key: 'period_to',
            label: l.adminPeriodTo,
            kind: AdminFieldKind.number),
        AdminField(
            key: 'description',
            label: l.adminDescriptionShort,
            kind: AdminFieldKind.multiline),
        AdminField(
            key: 'display_order',
            label: l.adminDisplayOrder,
            kind: AdminFieldKind.number),
      ];
    case 'competitions':
      return [
        AdminField(key: 'name_ar', label: l.adminNameAr),
        AdminField(key: 'name_en', label: l.adminNameEn, ltr: true),
        AdminField(key: 'season', label: l.adminSeason),
        AdminField(
            key: 'status',
            label: l.adminStatus,
            kind: AdminFieldKind.select,
            options: _competitionStatus(l)),
        AdminField(
            key: 'league_id',
            label: l.adminLeagueIdOptional,
            kind: AdminFieldKind.number),
        AdminField(
            key: 'display_order',
            label: l.adminDisplayOrder,
            kind: AdminFieldKind.number),
      ];
    default:
      return const [];
  }
}
