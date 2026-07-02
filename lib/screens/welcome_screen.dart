import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/clay_button.dart';
import '../widgets/clay_icon_button.dart';

/// App entry screen. Logo + welcome copy + login/register buttons + social
/// login row, with the field illustration flush at the bottom.
///
/// Not a bottom-nav tab: this is its own full-bleed white Scaffold.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goToApp(BuildContext context) => context.go('/login');

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.comingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBgWhite,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Logo box
                      Padding(
                        padding: const EdgeInsets.fromLTRB(36, 20, 36, 4),
                        child: Center(
                          child: Container(
                            width: 230,
                            height: 118,
                            decoration: BoxDecoration(
                              color: AppColors.screenBgWhite,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/iqs-logo.jpeg',
                              width: 176,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),

                      // 2 + 3. Welcome text + subtitle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(38, 14, 38, 0),
                        child: Column(
                          children: [
                            Text(
                              context.l10n.authWelcomeTitle,
                              textAlign: TextAlign.center,
                              style: AppText.tajawal(
                                size: 28,
                                weight: AppText.extraBold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.l10n.authWelcomeSubtitle,
                              textAlign: TextAlign.center,
                              style: AppText.tajawal(
                                size: 15,
                                weight: AppText.medium,
                                color: AppColors.sectionLabel,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Buttons block
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 22, 30, 0),
                        child: Column(
                          children: [
                            // Login (green 3D)
                            Clay3DButton(
                              label: context.l10n.authLoginButton,
                              gradient: AppColors.login3d,
                              hardShadow: AppColors.login3dHardShadow,
                              softShadow: [
                                BoxShadow(
                                  color: const Color(0xFF19773B)
                                      .withValues(alpha: .55),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -6,
                                ),
                              ],
                              height: 66,
                              radius: 22,
                              restDrop: 6,
                              pressDrop: 1,
                              onTap: () => _goToApp(context),
                              trailing: const Directionality(
                                textDirection: TextDirection.ltr,
                                child: ClayCircleBadge(
                                  icon: Icons.arrow_forward,
                                  size: 46,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Register (white outline)
                            ClayOutlineButton(
                              label: context.l10n.authRegisterButton,
                              onTap: () => _goToApp(context),
                              trailing: const ClayCircleBadge(
                                icon: Icons.person_add_alt_1,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFFFFFFFF), Color(0xFFEEF4EF)],
                                ),
                                iconColor: AppColors.primaryGreen,
                                iconSize: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 5. Social block
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
                        child: Column(
                          children: [
                            Text(
                              context.l10n.authSocialLoginLabel,
                              textAlign: TextAlign.center,
                              style: AppText.tajawal(
                                size: 14,
                                weight: AppText.medium,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClaySocialButton(
                                  size: 62,
                                  onTap: () => _comingSoon(context),
                                  child: Text(
                                    'G',
                                    style: AppText.tajawal(
                                      size: 26,
                                      weight: AppText.black,
                                      color: const Color(0xFF4285F4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                ClaySocialButton(
                                  size: 62,
                                  onTap: () => _comingSoon(context),
                                  child: const Icon(
                                    Icons.apple,
                                    size: 26,
                                    color: Color(0xFF11151B),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                ClaySocialButton(
                                  size: 62,
                                  onTap: () => _comingSoon(context),
                                  child: const Icon(
                                    Icons.facebook,
                                    size: 28,
                                    color: Color(0xFF1877F2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // spacer pushes the footer image to the very bottom
                      const Expanded(child: SizedBox(height: 60)),

                      // 6. Footer field image, flush at the bottom, full width
                      IgnorePointer(
                        child: Image.asset(
                          'assets/footer-field.png',
                          fit: BoxFit.fitWidth,
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
