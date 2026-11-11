import 'package:flutter/animation.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'GoBuy';
  static const String appTagline = 'Good finds. Better prices.';
  static const String appVersion = '1.0.0'; // keep in sync with pubspec.yaml

  // ---- Spacing ------------------------------------------------------------
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceSM = 12;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;

  /// Horizontal page padding on every screen.
  static const double pagePadding = 20;

  /// Horizontal padding on auth screens and onboarding text panels.
  static const double panelPadding = 24;

  /// Bottom padding on scrollable tab content so the last item clears the
  /// bottom nav bar.
  static const double listBottomInset = 100;

  // ---- Sizes --------------------------------------------------------------
  static const double fieldHeight = 50;
  static const double iconButtonSize = 40;
  static const double minTapTarget = 44;
  static const double categoryCircleSize = 58;

  // ---- Radii --------------------------------------------------------------
  static const double radiusS = 8;
  static const double radiusIconWell = 10;
  static const double radiusInput = 14;
  static const double radiusM = 16; // list cards, product image tile
  static const double radiusL = 20; // hero / dark cards
  static const double radiusProductCard = 22;
  static const double radiusSheet = 24;
  static const double radiusXL = 28; // onboarding panel, large sheets
  static const double radiusPill = 100;

  // ---- Motion (use these values everywhere) -------------------------------
  /// Button press feedback (scale to [pressScale]).
  static const Duration animPress = Duration(milliseconds: 120);
  static const double pressScale = 0.97;

  /// Toggle / selection changes.
  static const Duration animToggle = Duration(milliseconds: 180);

  /// Page transitions (fade-through; pushed routes slide from the right).
  static const Duration animPage = Duration(milliseconds: 220);

  /// Screen content entrance: fade 0→1 + slideY 0.04→0.
  static const Duration animEntrance = Duration(milliseconds: 250);
  static const double entranceSlideY = 0.04;
  static const Curve animCurve = Curves.easeOutCubic;

  /// Grid/list stagger per item, and how many items get animated.
  static const Duration staggerStep = Duration(milliseconds: 40);
  static const int staggerMaxItems = 8;

  // Legacy durations, now mapped onto the motion tokens above.
  static const Duration animMicro = animPress;
  static const Duration animFast = animToggle;
  static const Duration animMedium = animEntrance;
  static const Duration animSlow = Duration(milliseconds: 800); // splash only

  /// One cycle of a looping skeleton loader.
  static const Duration animShimmer = Duration(milliseconds: 1100);

  // ---- Debounce (network calls after typing stops) ------------------------
  static const Duration debounceFast = Duration(milliseconds: 450);
  static const Duration debounceSlow = Duration(milliseconds: 600);

  // ---- Storage keys -------------------------------------------------------
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefLocale = 'pref_locale';
  static const String prefOnboardingSeen = 'pref_onboarding_seen';
}
