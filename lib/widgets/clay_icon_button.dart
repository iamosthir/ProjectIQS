import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/clay.dart';
import 'pressable.dart';

/// Rounded-square green clay button used in the green headers (menu / bell /
/// back). Presses with a subtle scale-down.
class ClayHeaderButton extends StatelessWidget {
  const ClayHeaderButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 50,
    this.radius = 17,
    this.iconSize = 24,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double radius;
  final double iconSize;

  /// Yellow notification dot (bell button).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedScale(
          scale: pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: size,
            height: size,
            decoration: Clay.headerButton(radius: radius),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: iconSize, color: Colors.white),
                if (badge)
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD23D),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.headerBtnBottom, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Round white "social login" clay button (Google / Apple / Facebook).
class ClaySocialButton extends StatelessWidget {
  const ClaySocialButton({super.key, required this.child, this.onTap, this.size = 62});

  final Widget child;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedScale(
          scale: pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: AppColors.socialButton,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x171F5030), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F5030).withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFF1F5030).withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

/// Small circular gradient badge that holds an icon — used as the trailing
/// circle inside the Welcome buttons and similar embossed circles.
class ClayCircleBadge extends StatelessWidget {
  const ClayCircleBadge({
    super.key,
    required this.icon,
    this.size = 46,
    this.gradient,
    this.iconColor = Colors.white,
    this.iconSize = 22,
  });

  final IconData icon;
  final double size;
  final Gradient? gradient;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A9C52), Color(0xFF15722F)],
            ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

/// Embossed light-green square icon tile used in the More settings rows.
class SettingsIconTile extends StatelessWidget {
  const SettingsIconTile({super.key, required this.icon, this.size = 42, this.radius = 14});

  final IconData icon;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: Clay.settingsTile(radius: radius),
      child: Icon(icon, size: 22, color: AppColors.primaryGreen),
    );
  }
}
