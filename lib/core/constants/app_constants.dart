class AppConstants {
  AppConstants._();

  static const String appName = 'GoBuy';
  static const String appTagline = 'Your premium experience starts here';
  static const String appVersion = '1.0.0'; // keep in sync with pubspec.yaml

  // Spacing scale
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceSM = 12;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;
  static const double spaceXXL = 48;
  /// Bottom padding on scrollable tab content so the last item clears the
  /// bottom nav bar/FAB instead of sitting behind it. Was already the same
  /// literal `100` copy-pasted onto Home, Profile, and Settings — named so
  /// it stays that way instead of drifting per screen.
  static const double listBottomInset = 100;

  // Radii. `radiusM` is 16, not the more "logical" midpoint between S and
  // L, because that's the actual value already used everywhere in
  // `AppTheme` (inputs, buttons, cards) — the token was made to match the
  // established real corner radius rather than the other way around.
  static const double radiusS = 8;
  static const double radiusM = 16;
  static const double radiusL = 20;
  static const double radiusXL = 28;

  // Animation durations. `animMicro` covers press/fade feedback that's
  // deliberately quicker than a full screen-level transition — without it,
  // that whole tier of interaction (image fade-ins, tap scale-downs) has no
  // token to use and ends up as inline literals.
  static const Duration animMicro = Duration(milliseconds: 150);
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 800);
  /// One cycle of a looping shimmer/skeleton loader — a distinct concept
  /// from the one-shot transitions above.
  static const Duration animShimmer = Duration(milliseconds: 1100);

  // Debounce delays — distinct from the `anim*` family above: these gate a
  // network call after typing stops, not a visual transition. Two tiers
  // because a heavier API (place autocomplete) genuinely wants to wait
  // longer than a lighter one (in-app product search).
  static const Duration debounceFast = Duration(milliseconds: 450);
  static const Duration debounceSlow = Duration(milliseconds: 600);

  // Storage keys
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefLocale = 'pref_locale';
  static const String prefOnboardingSeen = 'pref_onboarding_seen';
}
