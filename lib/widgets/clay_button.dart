import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'pressable.dart';

/// A "physical" 3D clay button: a soft outer drop shadow plus a hard,
/// zero-blur offset shadow underneath (`0 Ny 0 0 color`) so the face looks
/// like a raised block. On press the whole face translates down and the hard
/// shadow collapses, so the button visibly drops onto its base.
///
/// Used by the Welcome "تسجيل الدخول" (green) and More "تسجيل الخروج" (red).
class Clay3DButton extends StatelessWidget {
  const Clay3DButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.hardShadow,
    required this.softShadow,
    this.onTap,
    this.height = 66,
    this.radius = 22,
    this.labelColor = Colors.white,
    this.labelSize = 19,
    this.restDrop = 6,
    this.pressDrop = 1,
    this.border,
    this.leading,
    this.trailing,
  });

  final String label;
  final Gradient gradient;
  final Color hardShadow;
  final List<BoxShadow> softShadow;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final Color labelColor;
  final double labelSize;
  final double restDrop;
  final double pressDrop;
  final BoxSide? border;

  /// Inline icon shown before the label (e.g. logout door icon).
  final Widget? leading;

  /// Widget pinned to the right edge of the button (e.g. circle arrow badge).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        final double drop = pressed ? pressDrop : restDrop;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: double.infinity,
          height: height,
          transform: Matrix4.translationValues(0, pressed ? (restDrop - pressDrop) : 0, 0),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: border == null
                ? null
                : Border.all(color: border!.color, width: border!.width),
            boxShadow: [
              ...softShadow,
              BoxShadow(color: hardShadow, offset: Offset(0, drop), blurRadius: 0),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Text(
                    label,
                    style: AppText.tajawal(
                      size: labelSize,
                      weight: AppText.bold,
                      color: labelColor,
                    ),
                  ),
                ],
              ),
              if (trailing != null)
                Positioned(right: 12, child: trailing!),
            ],
          ),
        );
      },
    );
  }
}

/// Simple value object for an optional border on [Clay3DButton].
class BoxSide {
  const BoxSide(this.color, this.width);
  final Color color;
  final double width;
}

/// White face with a green border that scales slightly on press. Used by the
/// Welcome "إنشاء حساب جديد" button (no 3D drop).
class ClayOutlineButton extends StatelessWidget {
  const ClayOutlineButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 66,
    this.radius = 22,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      builder: (context, pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: double.infinity,
          height: height,
          transform: Matrix4.identity()
            ..scaleByDouble(pressed ? 0.985 : 1.0, pressed ? 0.985 : 1.0, 1.0, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F6F2)],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFF2F9E52), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: AppText.tajawal(
                  size: 19,
                  weight: AppText.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
              if (trailing != null) Positioned(right: 12, child: trailing!),
            ],
          ),
        );
      },
    );
  }
}
