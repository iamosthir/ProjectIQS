import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Claymorphism shadow recipes.
///
/// Flutter's [BoxShadow] cannot render *inset* shadows, so the inner
/// highlight/shade that the CSS mockups achieve with `inset` shadows is
/// approximated here with: a top→bottom surface gradient (light top, faint
/// green bottom) + a 1px light border. The outer stacked drop-shadows are
/// reproduced faithfully with multiple [BoxShadow]s.
class Clay {
  Clay._();

  // ---- Outer drop shadows for a raised white card ----
  // outer:  rgba(28,80,48,.18) blur 30 y16 spread -10
  // outer2: rgba(28,80,48,.10) blur 12 y6  spread -5
  static const Color _shadowBase = Color(0xFF1C5030); // rgba(28,80,48)

  static List<BoxShadow> raisedShadows({double scale = 1.0}) => [
    BoxShadow(
      color: _shadowBase.withValues(alpha: 0.18),
      blurRadius: 30 * scale,
      offset: Offset(0, 16 * scale),
      spreadRadius: -10 * scale,
    ),
    BoxShadow(
      color: _shadowBase.withValues(alpha: 0.10),
      blurRadius: 12 * scale,
      offset: Offset(0, 6 * scale),
      spreadRadius: -5 * scale,
    ),
  ];

  /// Pressed/active: collapse the outer shadow so the surface appears to sink.
  static List<BoxShadow> pressedShadows() => [
    BoxShadow(
      color: _shadowBase.withValues(alpha: 0.16),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: -8,
    ),
  ];

  /// Standard raised white card decoration.
  static BoxDecoration card({
    double radius = 22,
    Gradient? gradient,
    bool pressed = false,
    Color? borderColor,
  }) {
    return BoxDecoration(
      gradient: gradient ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AppColors.cardBorder, width: 1),
      boxShadow: pressed ? pressedShadows() : raisedShadows(),
    );
  }

  /// Raised card with a stronger drop (used by big match cards / profile).
  static BoxDecoration cardStrong({double radius = 24, bool pressed = false}) {
    return BoxDecoration(
      gradient: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.cardBorder, width: 1),
      boxShadow: pressed
          ? pressedShadows()
          : [
              BoxShadow(
                color: _shadowBase.withValues(alpha: 0.20),
                blurRadius: 30,
                offset: const Offset(0, 16),
                spreadRadius: -10,
              ),
              BoxShadow(
                color: _shadowBase.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 7),
                spreadRadius: -5,
              ),
            ],
    );
  }

  /// The green header square button face.
  static BoxDecoration headerButton({double radius = 17}) {
    return BoxDecoration(
      gradient: AppColors.headerBtn,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
          spreadRadius: -5,
        ),
      ],
    );
  }

  /// Embossed circular badge (team crest / avatar) — outer drop + light ring.
  static BoxDecoration circle(Gradient gradient, {Color? ring}) {
    return BoxDecoration(
      gradient: gradient,
      shape: BoxShape.circle,
      border: Border.all(color: ring ?? Colors.white.withValues(alpha: 0.85), width: 2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF14284A).withValues(alpha: 0.40),
          blurRadius: 14,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ],
    );
  }

  /// Small settings-row icon tile (embossed light-green square).
  static BoxDecoration settingsTile({double radius = 14}) {
    return BoxDecoration(
      gradient: AppColors.settingsTile,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Active bottom-nav / pill tile (green gradient with glow).
  static BoxDecoration activePill({double radius = 18}) {
    return BoxDecoration(
      gradient: AppColors.primary,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1D8040).withValues(alpha: 0.55),
          blurRadius: 16,
          offset: const Offset(0, 10),
          spreadRadius: -5,
        ),
      ],
    );
  }
}
