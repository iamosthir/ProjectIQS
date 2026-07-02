import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/core_providers.dart';
import '../core/network/api_exception.dart';
import '../core/util/asset_url.dart';
import '../features/auth/application/auth_providers.dart';
import '../core/i18n/locale_provider.dart';
import '../shared/l10n/l10n_ext.dart';
import '../shared/models/user.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/clay.dart';
import '../widgets/app_header.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_card.dart';
import '../widgets/clay_icon_button.dart';
import '../widgets/clay_toggle.dart';
import '../widgets/network_image_box.dart';
import '../widgets/pressable.dart';

/// The "المزيد" (More) screen: profile card, grouped settings lists with
/// claymorphism rows, and a 3D logout button. Mirrors `ui/IQS More.dc.html`.
///
/// Phase 9 wires it to real data: profile from `/auth/me`, edit-profile,
/// language toggle (ar/en → locale provider + `PUT /auth/profile`), legal pages,
/// role-gated service tiles, payments history, notifications preference, and
/// delete-account. Per Decision C the dark-mode toggle is hidden (no dark
/// palette yet); per Decision F the favorites row collapses to the single
/// supported club (the decorative count pill is dropped).
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  late bool _notif = ref.read(appPrefsProvider).notificationsEnabled;

  Future<void> _setNotif(bool v) async {
    setState(() => _notif = v);
    await ref.read(appPrefsProvider).setNotificationsEnabled(v);
  }

  Future<void> _toggleLanguage() async {
    final next = ref.read(localeProvider).languageCode == 'ar' ? 'en' : 'ar';
    await ref.read(localeProvider.notifier).setLocale(next);
    // Persist server-side so reads come back in the chosen language (best-effort).
    try {
      await ref.read(authProvider.notifier).updateProfile({'locale': next});
    } catch (_) {/* locale already applied locally */}
  }

  void _openFavorites(User? user) {
    final id = user?.supportedClubId;
    // Decision F: single supported club → its profile; none → clubs directory.
    context.push(id != null ? '/clubs/$id' : '/news');
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.screenBgWhite,
        title: Text(context.l10n.notifDeleteAccount,
            style: AppText.sectionHeader),
        content: Text(
          context.l10n.notifDeleteAccountBody,
          style: AppText.muted,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel, style: AppText.muted)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.notifDeleteAccountConfirm,
                style: AppText.tajawal(
                    size: 14, weight: AppText.bold, color: AppColors.logoutText)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      // Clears the token → the auth redirect lands on /welcome.
      await ref.read(authProvider.notifier).deleteAccount();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== GREEN HEADER (scrolls away) =====
            const AppHeader(
              gradient: AppColors.header,
              bottomRadius: 36,
              padding: EdgeInsets.fromLTRB(22, 10, 22, 70),
              child: Center(child: _HeaderTitle()),
            ),

            // ===== CONTENT (overlaps header by 56px) =====
            Transform.translate(
              offset: const Offset(0, -56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(user),

                  // GROUP: الحساب
                  _groupLabel(context.l10n.notifGroupAccount, topPadding: 24),
                  _group([
                    _SettingsRow(
                      icon: Icons.person_outline,
                      label: context.l10n.notifRowProfile,
                      onTap: () => context.push('/profile/edit'),
                      trailing: const _Chevron(),
                    ),
                    _SettingsRow(
                      icon: Icons.star_rounded,
                      label: context.l10n.notifRowFavoriteClubs,
                      onTap: () => _openFavorites(user),
                      trailing: const _Chevron(),
                    ),
                    _SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      label: context.l10n.notifRowNotifications,
                      trailing: ClayToggle(value: _notif, onChanged: _setNotif),
                    ),
                  ]),

                  // GROUP: خدماتي (role-gated entry points + payments)
                  _groupLabel(context.l10n.notifGroupServices, topPadding: 22),
                  _group([
                    _SettingsRow(
                      icon: Icons.storefront_outlined,
                      label: context.l10n.notifRowMyStore,
                      onTap: () => context.push('/market/my-store'),
                      trailing: const _Chevron(),
                    ),
                    if (user?.hasRole('club-admin') ?? false)
                      _SettingsRow(
                        icon: Icons.shield_outlined,
                        label: context.l10n.notifRowMyClub,
                        onTap: () => context.push('/my-club'),
                        trailing: const _Chevron(),
                      ),
                    if (user?.hasRole('group-admin') ?? false)
                      _SettingsRow(
                        icon: Icons.campaign_outlined,
                        label: context.l10n.notifRowMyFanGroup,
                        onTap: () => context.push('/my-fan-group'),
                        trailing: const _Chevron(),
                      ),
                    _SettingsRow(
                      icon: Icons.payments_outlined,
                      label: context.l10n.notifRowPayments,
                      onTap: () => context.push('/payments'),
                      trailing: const _Chevron(),
                    ),
                  ]),

                  // GROUP: التطبيق
                  _groupLabel(context.l10n.notifGroupApp, topPadding: 22),
                  _group([
                    _SettingsRow(
                      icon: Icons.language,
                      label: context.l10n.notifRowLanguage,
                      onTap: _toggleLanguage,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAr ? context.l10n.notifLangArabic : 'English',
                            style: AppText.tajawal(
                              size: 13,
                              weight: AppText.medium,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _Chevron(),
                        ],
                      ),
                    ),
                    // Decision C: the dark-mode toggle is hidden until a dark
                    // clay palette exists (no dead control shipped).
                    _SettingsRow(
                      icon: Icons.info_outline,
                      label: context.l10n.notifRowAbout,
                      onTap: () => context.push('/page/about'),
                      trailing: const _Chevron(),
                    ),
                  ]),

                  // GROUP: الدعم
                  _groupLabel(context.l10n.notifGroupSupport, topPadding: 22),
                  _group([
                    _SettingsRow(
                      icon: Icons.help_outline,
                      label: context.l10n.notifRowHelpCenter,
                      onTap: () => context.push('/page/terms'),
                      trailing: const _Chevron(),
                    ),
                    _SettingsRow(
                      icon: Icons.shield_outlined,
                      label: context.l10n.notifRowPrivacy,
                      onTap: () => context.push('/page/privacy'),
                      trailing: const _Chevron(),
                    ),
                    _SettingsRow(
                      icon: Icons.delete_outline,
                      label: context.l10n.notifDeleteAccount,
                      onTap: _confirmDelete,
                      trailing: const _Chevron(),
                    ),
                  ]),

                  // ===== LOGOUT =====
                  _buildLogout(),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Profile card -------------------------------------------------------

  Widget _buildProfileCard(User? user) {
    final avatarUrl = assetUrl(user?.avatar);
    final name =
        (user?.name?.isNotEmpty ?? false) ? user!.name! : context.l10n.notifDefaultUserName;
    final subtitle = (user?.governorate?.isNotEmpty ?? false)
        ? user!.governorate!
        : (user?.phone ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClayCard(
        strong: true,
        radius: 26,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Avatar with edit badge.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    gradient: AppColors.avatar,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1C5A32).withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 40)
                      : NetworkImageBox(url: avatarUrl, fit: BoxFit.cover),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: AppColors.knob,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 13,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Name + subtitle.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tajawal(
                      size: 19,
                      weight: AppText.extraBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppText.muted,
                    ),
                  ),
                ],
              ),
            ),

            // "تعديل" green button.
            Pressable(
              onTap: () => context.push('/profile/edit'),
              builder: (context, pressed) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green1D8040.withValues(alpha: 0.5),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Text(
                    context.l10n.edit,
                    style: AppText.tajawal(
                      size: 13,
                      weight: AppText.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---- Grouped list helpers ----------------------------------------------

  Widget _groupLabel(String title, {required double topPadding}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding, 24, 12),
      child: Text(title, style: AppText.groupLabel),
    );
  }

  Widget _group(List<Widget> rows) {
    final List<Widget> children = [];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(
          const Divider(color: AppColors.divider, height: 1, thickness: 1),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        decoration: Clay.card(radius: 22, gradient: AppColors.surface),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  // ---- Logout -------------------------------------------------------------

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Clay3DButton(
            label: context.l10n.notifLogout,
            gradient: AppColors.logout,
            hardShadow: AppColors.logoutHardShadow,
            softShadow: [
              BoxShadow(
                color: AppColors.logoutText.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 12),
                spreadRadius: -10,
              ),
            ],
            labelColor: AppColors.logoutText,
            labelSize: 17,
            height: 60,
            radius: 20,
            restDrop: 5,
            pressDrop: 1,
            border: const BoxSide(AppColors.logoutBorder, 1),
            leading: const Icon(
              Icons.logout,
              color: AppColors.logoutText,
              size: 22,
            ),
            onTap: () => widget.onLogout?.call(),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              context.l10n.notifVersion,
              style: AppText.tajawal(
                size: 12,
                weight: AppText.medium,
                color: const Color(0xFFAAB4AD),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header title — separated so the [AppHeader] child can stay const.
class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.navMore,
      style: AppText.tajawal(
        size: 24,
        weight: AppText.extraBold,
        color: Colors.white,
      ),
    );
  }
}

/// A single settings row: embossed icon tile (RTL → on the right), a label, and
/// a trailing widget (chevron / pill / toggle) on the left.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      child: Row(
        children: [
          SettingsIconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppText.rowLabel)),
          trailing,
        ],
      ),
    );
    if (onTap == null) return row;
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return Container(
          color: pressed ? AppColors.rowPressed : Colors.transparent,
          child: row,
        );
      },
    );
  }
}

/// The left-edge disclosure chevron (RTL points left).
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_left,
      size: 20,
      color: AppColors.chevron,
    );
  }
}
