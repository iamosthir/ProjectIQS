import 'package:flutter/material.dart';

/// Design tokens — colors extracted verbatim from the `ui/*.dc.html` mockups.
///
/// These are the single source of truth for color across the app. Gradients are
/// exposed as ready-to-use [LinearGradient]/[RadialGradient] objects where the
/// mockups use CSS gradients.
class AppColors {
  AppColors._();

  // ---- Surfaces / backgrounds ----
  static const Color screenBg = Color(0xFFEEF3EE); // Home / Matches / More
  static const Color screenBgWhite = Color(0xFFFFFFFF); // Welcome / News
  static const Color surfaceTop = Color(0xFFFFFFFF);
  static const Color surfaceBottom = Color(0xFFFAFDFB);
  static const Color iconTileTop = Color(0xFFF1F6F2); // section icon tiles

  // ---- Greens ----
  static const Color primaryGreen = Color(0xFF1F8A45); // solid primary
  static const Color green2AA153 = Color(0xFF2AA153);
  static const Color green1D8040 = Color(0xFF1D8040);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1C2620);
  static const Color textMuted = Color(0xFF9AA69F);
  static const Color sectionLabel = Color(0xFF7D8A82);
  static const Color textOnGreen = Color(0xFFFFFFFF);
  static const Color textSubtleGreen = Color(0xFF33433A);

  // ---- Pills / badges ----
  static const Color pillBg = Color(0xFFE9F5EC);
  static const Color pillText = Color(0xFF2AA153);

  // ---- Logout (red) ----
  static const Color logoutText = Color(0xFFE2483F);
  static const Color logoutBgBottom = Color(0xFFFDEEED);
  static const Color logoutHardShadow = Color(0xFFF3DAD8);
  static const Color logoutBorder = Color(0x24E2483F); // rgba(226,72,63,.14)

  // ---- Lines / borders ----
  static const Color divider = Color(0xFFEEF2EE);
  static const Color cardBorder = Color(0x141F8040); // rgba(31,128,64,0.08)
  static const Color infoDivider = Color(0xFFE9EEE9);

  // ---- Chevron / disclosure ----
  static const Color chevron = Color(0xFFC2CCC5);

  // ---- Filter chips (Matches) ----
  static const Color chipInactiveText = Color(0xFF3A6B4C);

  // ---- Tab chips (News) ----
  static const Color tabInactiveText = Color(0xFF5D6B62);
  static const Color tabInactiveBottom = Color(0xFFF4F8F5);

  // ---- Welcome 3D button ----
  static const Color login3dTop = Color(0xFF34A85A);
  static const Color login3dMid = Color(0xFF1F8A45);
  static const Color login3dBottom = Color(0xFF19773B);
  static const Color login3dHardShadow = Color(0xFF135C2C);

  // ---- Header square clay buttons ----
  static const Color headerBtnTop = Color(0xFF4CB472);
  static const Color headerBtnBottom = Color(0xFF2C8A4F);

  // ---- Settings-row icon tile ----
  static const Color settingsTileTop = Color(0xFFEAF6EE);
  static const Color settingsTileBottom = Color(0xFFDCEFE2);
  static const Color rowPressed = Color(0xFFF6FAF7);

  // ---- Toggle ----
  static const Color toggleOffTop = Color(0xFFDFE6E0);
  static const Color toggleOffBottom = Color(0xFFCFD8D1);
  static const Color knobBottom = Color(0xFFEEF2EE);

  // ---- Slider ----
  static const Color sliderBg = Color(0xFF0C2A17);

  // ====================================================================
  // Gradients
  // ====================================================================

  /// Green page background that sits *behind the phone* in the mockups — used
  /// only for placeholder / video screen flourishes, never as a screen bg.
  static const LinearGradient pageGreen = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF56B277), Color(0xFF3F9E63), Color(0xFF2F8A52)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Standard header gradient (165deg #42A967 → #319457 → #23823F).
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF42A967), Color(0xFF319457), Color(0xFF23823F)],
    stops: [0.0, 0.55, 1.0],
  );

  /// News-screen header variant (slightly different greens).
  static const LinearGradient headerNews = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF3FA564), Color(0xFF2F9355), Color(0xFF23823F)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary green button / active-state gradient (180deg).
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2AA153), Color(0xFF1D8040)],
  );

  /// White raised surface (top→bottom subtle).
  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFDFB)],
  );

  /// Welcome login 3D button face.
  static const LinearGradient login3d = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF34A85A), Color(0xFF1F8A45), Color(0xFF19773B)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Header square clay button face.
  static const LinearGradient headerBtn = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4CB472), Color(0xFF2C8A4F)],
  );

  /// Settings-row embossed icon tile.
  static const LinearGradient settingsTile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF6EE), Color(0xFFDCEFE2)],
  );

  /// White section icon tile (Home "أقسام التطبيق").
  static const LinearGradient sectionTile = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F6F2)],
  );

  /// Logout button face (white → faint red).
  static const LinearGradient logout = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFDEEED)],
  );

  /// Toggle track when ON.
  static const LinearGradient toggleOn = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2AA153), Color(0xFF1D8040)],
  );

  /// Toggle track when OFF.
  static const LinearGradient toggleOff = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDFE6E0), Color(0xFFCFD8D1)],
  );

  /// Toggle knob.
  static const LinearGradient knob = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFEEF2EE)],
  );

  /// Round social-login button face (radial).
  static const RadialGradient socialButton = RadialGradient(
    center: Alignment(-0.3, -0.5),
    radius: 1.2,
    colors: [Color(0xFFFFFFFF), Color(0xFFF3F6F3)],
  );

  /// Profile avatar (More screen).
  static const RadialGradient avatar = RadialGradient(
    center: Alignment(-0.3, -0.5),
    radius: 1.2,
    colors: [Color(0xFF4CB472), Color(0xFF23823F)],
  );

  /// Dark overlay applied over slider images for text legibility.
  static const LinearGradient sliderOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x0D081E10), // rgba(8,30,16,.05)
      Color(0x8C081E10), // rgba(8,30,16,.55)
      Color(0xEB081E10), // rgba(8,30,16,.92)
    ],
    stops: [0.30, 0.62, 1.0],
  );

  /// Builds a crest gradient for a team color (radial sheen, top-left light).
  static RadialGradient crest(Color base) {
    final HSLColor hsl = HSLColor.fromColor(base);
    final Color light = hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .toColor();
    return RadialGradient(
      center: const Alignment(-0.3, -0.5),
      radius: 1.2,
      colors: [light, base],
    );
  }
}
