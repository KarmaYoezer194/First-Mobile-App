import 'package:flutter/material.dart';

/// Centralized color palette — "Warm Ivory". Keep all raw color values here
/// so the rest of the app only references semantic names.
///
/// One accent (gold) per screen, used sparingly. No gradients on UI
/// surfaces, no colored shadows.
///
/// Widgets that must follow light/dark mode should read colors from the
/// theme (`Theme.of(context).colorScheme` or `context.palette`) instead of
/// these constants, which are the light-mode values.
class AppColors {
  AppColors._();

  // ---- Light tokens -------------------------------------------------------
  static const Color background = Color(0xFFF7F2EA); // warm ivory page
  static const Color surface = Color(0xFFFFFFFF); // cards, inputs, nav, sheets
  static const Color surfaceSoft =
      Color(0xFFF0E8DB); // icon wells, stepper buttons
  static const Color tile = Color(0xFFEEE7DC); // product image tile
  static const Color border = Color(0xFFECE4D8); // hairlines, dividers
  static const Color borderStrong = Color(0xFFDCCFBD); // outline buttons
  static const Color switchTrackOff =
      Color(0xFFE2D8C9); // also secondary-button border
  static const Color ink =
      Color(0xFF2B2420); // text, primary buttons, dark cards
  static const Color inkMuted = Color(0xFF6B6054); // secondary text
  static const Color hint =
      Color(0xFFA89C8C); // placeholders, meta, section labels
  static const Color navInactive = Color(0xFFB3A696);
  static const Color gold = Color(0xFFC8902E); // the one accent
  static const Color goldLight = Color(0xFFE2B566); // gold on ink surfaces
  static const Color success = Color(0xFF5E7D5A);
  static const Color danger = Color(0xFFA2483A);
  static const Color dangerBg = Color(0xFFF6E3DC);
  static const Color profileEmail =
      Color(0xFFBFB3A2); // muted text on ink cards

  // ---- Dark tokens --------------------------------------------------------
  static const Color darkBackground = Color(0xFF1E1A17);
  static const Color darkSurface = Color(0xFF2B2420);
  static const Color darkSurfaceSoft = Color(0xFF3A322C);
  static const Color darkTile = Color(0xFF342D27);
  static const Color darkBorder = Color(0xFF3F3630);
  static const Color darkBorderStrong = Color(0xFF51463E);
  static const Color darkText = Color(0xFFF7F2EA);
  static const Color darkTextMuted = Color(0xFFBFB3A2);
  static const Color darkHint = Color(0xFF8F8273);
  static const Color darkDangerBg = Color(0xFF4A2A24);

  // ---- Illustration only (onboarding art) ---------------------------------
  static const Color illoTerra = Color(0xFFC96F4A);
  static const Color illoSage = Color(0xFF8A9E7E);
  static const Color illoBlush = Color(0xFFEFC9B4);
  static const Color illoSand = Color(0xFFE6D7C1);
  static const Color illoCream = Color(0xFFFFFDF8);

  /// Onboarding slide backgrounds, slides 1–3.
  static const List<Color> onboardingBackgrounds = [
    Color(0xFFE9DCC8),
    Color(0xFFDCE2D2),
    Color(0xFFF2DCCB),
  ];

  // ---- Brand logos ------------------------------------------------------
  /// Facebook's logo blue, for the "Continue with Facebook" button only.
  static const Color brandFacebook = Color(0xFF1877F2);
}

/// Brightness-aware tokens that `ColorScheme` has no slot for (tile, hint,
/// gold, etc.). Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.tile,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkMuted,
    required this.hint,
    required this.navInactive,
    required this.gold,
    required this.goldLight,
    required this.success,
    required this.danger,
    required this.dangerBg,
    required this.switchTrackOff,
    required this.heroCard,
    required this.onHeroCard,
  });

  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color tile;
  final Color border;
  final Color borderStrong;

  /// Primary text color (cream in dark mode).
  final Color ink;
  final Color inkMuted;
  final Color hint;
  final Color navInactive;
  final Color gold;
  final Color goldLight;
  final Color success;
  final Color danger;
  final Color dangerBg;
  final Color switchTrackOff;

  /// Dark "ink" cards (Home hero, Profile header, free-shipping banner).
  /// Stays dark in both modes.
  final Color heroCard;
  final Color onHeroCard;

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceSoft: AppColors.surfaceSoft,
    tile: AppColors.tile,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    ink: AppColors.ink,
    inkMuted: AppColors.inkMuted,
    hint: AppColors.hint,
    navInactive: AppColors.navInactive,
    gold: AppColors.gold,
    goldLight: AppColors.goldLight,
    success: AppColors.success,
    danger: AppColors.danger,
    dangerBg: AppColors.dangerBg,
    switchTrackOff: AppColors.switchTrackOff,
    heroCard: AppColors.ink,
    onHeroCard: AppColors.background,
  );

  static const dark = AppPalette(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceSoft: AppColors.darkSurfaceSoft,
    tile: AppColors.darkTile,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    ink: AppColors.darkText,
    inkMuted: AppColors.darkTextMuted,
    hint: AppColors.darkHint,
    navInactive: AppColors.darkHint,
    gold: AppColors.gold,
    goldLight: AppColors.goldLight,
    success: Color(0xFF8BAA86),
    danger: Color(0xFFD9806F),
    dangerBg: AppColors.darkDangerBg,
    switchTrackOff: AppColors.darkBorderStrong,
    heroCard: AppColors.darkSurfaceSoft,
    onHeroCard: AppColors.darkText,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceSoft: l(surfaceSoft, other.surfaceSoft),
      tile: l(tile, other.tile),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      hint: l(hint, other.hint),
      navInactive: l(navInactive, other.navInactive),
      gold: l(gold, other.gold),
      goldLight: l(goldLight, other.goldLight),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      dangerBg: l(dangerBg, other.dangerBg),
      switchTrackOff: l(switchTrackOff, other.switchTrackOff),
      heroCard: l(heroCard, other.heroCard),
      onHeroCard: l(onHeroCard, other.onHeroCard),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Brightness-aware Warm Ivory tokens for the current theme.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
