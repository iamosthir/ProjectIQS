import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The green gradient header used at the top of Home / Matches / News / More.
///
/// Extends under the real device status bar (green shows through) and pads its
/// content below the status bar via [SafeArea]. A faint soccer-ball watermark
/// sits behind the content, mirroring the mockups.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.child,
    this.gradient = AppColors.header,
    this.bottomRadius = 36,
    this.padding = const EdgeInsets.fromLTRB(22, 8, 22, 18),
    this.watermark = true,
    this.clipChildren = false,
    this.shadow = true,
  });

  final Widget child;
  final Gradient gradient;
  final double bottomRadius;
  final EdgeInsets padding;
  final bool watermark;

  /// Clip overflow to the rounded shape (used by the News header banner).
  final bool clipChildren;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(bottom: Radius.circular(bottomRadius));
    final decorated = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: radius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0xFF1C5A32).withValues(alpha: 0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                  spreadRadius: -10,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (watermark)
            Positioned(
              top: 40,
              left: -30,
              child: Icon(
                Icons.sports_soccer,
                size: 170,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          SafeArea(bottom: false, child: Padding(padding: padding, child: child)),
        ],
      ),
    );
    if (!clipChildren) return decorated;
    return ClipRRect(borderRadius: radius, child: decorated);
  }
}
