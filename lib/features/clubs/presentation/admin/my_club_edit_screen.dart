import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/i18n/locale_provider.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/clubs/application/clubs_providers.dart';
import 'package:iqs_flutter/features/clubs/data/club_detail.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'admin_form.dart';
import 'club_admin_specs.dart';

/// Edit the managed club (`PUT /my-club`). Writes raw `_ar/_en`; name/description
/// prefill into the column matching the active locale (avoids cross-language
/// corruption on save).
class MyClubEditScreen extends ConsumerWidget {
  const MyClubEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myClubProvider);
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
                      child: Text(context.l10n.clubAdminEditClubTitle,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/my-club'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myClubProvider),
              data: (club) {
                final locale = ref.read(localeProvider).languageCode;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                  child: AdminFormBody(
                    fields: clubProfileFields(context.l10n),
                    initial: _initial(club, locale),
                    submitLabel: context.l10n.save,
                    // Always an edit (partial update) — server uses `sometimes`.
                    enforceRequired: false,
                    onSubmit: (body) => _submit(context, ref, body),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _initial(ClubDetail c, String locale) {
    final m = <String, String>{
      'governorate': c.governorate ?? '',
      'city': c.city ?? '',
      'address': c.address ?? '',
      'founded_year': c.foundedYear?.toString() ?? '',
      'phone': c.contact.phone ?? '',
      'email': c.contact.email ?? '',
      'website': c.contact.website ?? '',
      'facebook': c.contact.facebook ?? '',
      'instagram': c.contact.instagram ?? '',
      'twitter': c.contact.twitter ?? '',
    };
    if (locale == 'en') {
      m['name_en'] = c.name;
      if (c.description != null) m['description_en'] = c.description!;
    } else {
      m['name_ar'] = c.name;
      if (c.description != null) m['description_ar'] = c.description!;
    }
    return m;
  }

  Future<Map<String, String>?> _submit(
      BuildContext context, WidgetRef ref, Map<String, dynamic> body) async {
    try {
      await ref.read(clubsRepositoryProvider).updateMyClub(body);
      ref.invalidate(myClubProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.savedChanges)));
        context.pop();
      }
      return null;
    } on ApiException catch (e) {
      if (e.isValidation && e.errors != null) {
        final invalid = context.mounted ? context.l10n.clubAdminInvalidValue : '';
        return e.errors!
            .map((k, v) => MapEntry(k, v.isNotEmpty ? v.first : invalid));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
      return const {};
    }
  }
}
