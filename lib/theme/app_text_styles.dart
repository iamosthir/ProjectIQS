import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tajawal text styles (weights 400/500/700/800/900) used across the app.
///
/// [GoogleFonts] fetches Tajawal at runtime. The whole UI is RTL/Arabic.
class AppText {
  AppText._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  /// Base builder so every style funnels through Tajawal.
  static TextStyle tajawal({
    double size = 14,
    FontWeight weight = regular,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.tajawal(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(TextTheme base) => GoogleFonts.tajawalTextTheme(base);

  // ---- Common roles ----
  static TextStyle screenTitle = tajawal(size: 24, weight: extraBold, color: AppColors.textOnGreen);
  static TextStyle sectionHeader = tajawal(size: 18, weight: extraBold, color: AppColors.textPrimary);
  static TextStyle groupLabel = tajawal(size: 14, weight: bold, color: AppColors.sectionLabel);
  static TextStyle rowLabel = tajawal(size: 15, weight: bold, color: AppColors.textPrimary);
  static TextStyle muted = tajawal(size: 13, weight: medium, color: AppColors.textMuted);
  static TextStyle navActive = tajawal(size: 12, weight: bold, color: AppColors.primaryGreen);
  static TextStyle navInactive = tajawal(size: 12, weight: medium, color: AppColors.textMuted);
}
