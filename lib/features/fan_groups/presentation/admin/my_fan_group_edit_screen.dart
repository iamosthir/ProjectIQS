import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/i18n/locale_provider.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/clubs/presentation/admin/admin_form.dart';
import 'package:iqs_flutter/features/fan_groups/application/fan_groups_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'fan_group_admin_specs.dart';

/// Edit the managed fan group (`PUT /my-fan-group`). Writes raw `_ar/_en`;
/// name/description prefill into the column matching the active locale (avoids
/// cross-language corruption on save). Image `*_path` fields are not editable
/// on mobile (no upload endpoint) and stay untouched.
class MyFanGroupEditScreen extends ConsumerWidget {
  const MyFanGroupEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFanGroupProvider);
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
                      child: Text(context.l10n.fanAdminEditTitle,
                          style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.go('/my-fan-group'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncValueView(
              value: async,
              onRetry: () => ref.invalidate(myFanGroupProvider),
              data: (group) {
                final locale = ref.read(localeProvider).languageCode;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                  child: AdminFormBody(
                    fields: fanGroupProfileFields(context.l10n),
                    initial: _initial(group, locale),
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

  Map<String, String> _initial(FanGroupDetail g, String locale) {
    final m = <String, String>{
      'governorate': g.group.governorate ?? '',
      'city': g.group.city ?? '',
      'founded_year': g.group.foundedYear?.toString() ?? '',
      'phone': g.contact.phone ?? '',
      'facebook': g.contact.facebook ?? '',
      'instagram': g.contact.instagram ?? '',
      'twitter': g.contact.twitter ?? '',
    };
    if (locale == 'en') {
      m['name_en'] = g.name;
      if (g.description != null) m['description_en'] = g.description!;
    } else {
      m['name_ar'] = g.name;
      if (g.description != null) m['description_ar'] = g.description!;
    }
    return m;
  }

  Future<Map<String, String>?> _submit(
      BuildContext context, WidgetRef ref, Map<String, dynamic> body) async {
    try {
      await ref.read(fanGroupsRepositoryProvider).updateMyFanGroup(body);
      if (!context.mounted) return null;
      ref.invalidate(myFanGroupProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            SnackBar(content: Text(context.l10n.savedChanges)));
      context.pop();
      return null;
    } on ApiException catch (e) {
      if (e.isValidation && e.errors != null) {
        return e.errors!.map(
            (k, v) => MapEntry(k, v.isNotEmpty ? v.first : context.l10n.fanAdminInvalidValue));
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
