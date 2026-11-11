import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';

/// Shadows. Only product cards, floating map controls and the wishlist
/// heart get one — nothing else.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> productCard = [
    BoxShadow(color: Color(0x0A2B2420), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x242B2420), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// A panel sitting on top of the map (pickup place panel).
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x1A2B2420), blurRadius: 16, offset: Offset(0, -2)),
  ];
}

/// Font helpers for one-off styles the text theme doesn't cover
/// (e.g. the logo, big prices).
class AppFonts {
  AppFonts._();

  /// Serif display face (Lora).
  static TextStyle serif({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
    double? height,
  }) =>
      GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  /// UI sans face (Inter).
  static TextStyle sans({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

/// Central Material 3 theme definitions ("Warm Ivory"). Import
/// `AppTheme.light` / `AppTheme.dark` wherever a [ThemeData] is required.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ColorScheme _scheme(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      // Primary buttons: ink on ivory in light mode, inverted (cream bg,
      // ink text) in dark mode.
      primary: isDark ? AppColors.darkText : AppColors.ink,
      onPrimary: isDark ? AppColors.ink : AppColors.background,
      primaryContainer: p.surfaceSoft,
      onPrimaryContainer: p.ink,
      secondary: p.gold,
      onSecondary: AppColors.ink,
      secondaryContainer: p.surfaceSoft,
      onSecondaryContainer: p.ink,
      tertiary: p.success,
      onTertiary: Colors.white,
      error: p.danger,
      onError: Colors.white,
      errorContainer: p.dangerBg,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surfaceSoft,
      surfaceContainerHigh: p.surfaceSoft,
      surfaceContainerHighest: p.tile,
      outline: p.borderStrong,
      outlineVariant: p.border,
      shadow: AppColors.ink,
      scrim: AppColors.ink,
      inverseSurface: isDark ? AppColors.background : AppColors.ink,
      onInverseSurface: isDark ? AppColors.ink : AppColors.background,
      inversePrimary: p.goldLight,
      surfaceTint: Colors.transparent,
    );
  }

  static TextTheme _textTheme(Brightness brightness, AppPalette p) {
    final base = GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ).apply(bodyColor: p.ink, displayColor: p.ink);

    // Serif (Lora 700) for display/headline roles: logo, screen titles,
    // auth headlines, big prices. Inter for everything else.
    TextStyle? serif(TextStyle? s, double size, {double? height}) =>
        s?.merge(GoogleFonts.lora(
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: height,
          color: p.ink,
        ));

    return base.copyWith(
      displayLarge: serif(base.displayLarge, 48),
      displayMedium: serif(base.displayMedium, 32, height: 1.15),
      displaySmall: serif(base.displaySmall, 30, height: 1.15),
      headlineLarge: serif(base.headlineLarge, 28),
      headlineMedium: serif(base.headlineMedium, 26),
      headlineSmall: serif(base.headlineSmall, 22),
      titleLarge:
          base.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium:
          base.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      titleSmall:
          base.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 14),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 13),
      bodySmall: base.bodySmall?.copyWith(fontSize: 11, color: p.hint),
      labelLarge:
          base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      labelMedium:
          base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      labelSmall:
          base.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = isDark ? AppPalette.dark : AppPalette.light;
    final scheme = _scheme(p, brightness);
    final text = _textTheme(brightness, p);

    const pill = StadiumBorder();
    final inputRadius = BorderRadius.circular(AppConstants.radiusInput);
    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: c, width: w),
        );

    final buttonText =
        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 15);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _SlideFadePageTransitionsBuilder(),
        TargetPlatform.iOS: _SlideFadePageTransitionsBuilder(),
        TargetPlatform.macOS: _SlideFadePageTransitionsBuilder(),
        TargetPlatform.windows: _SlideFadePageTransitionsBuilder(),
        TargetPlatform.linux: _SlideFadePageTransitionsBuilder(),
        TargetPlatform.fuchsia: _SlideFadePageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.ink,
        iconTheme: IconThemeData(color: p.ink, size: 20),
        titleTextStyle: GoogleFonts.lora(
            fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIconColor: p.hint,
        suffixIconColor: p.hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: p.hint),
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: p.inkMuted),
        floatingLabelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: p.ink),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: p.danger),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.ink, 1.2),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(AppConstants.fieldHeight),
          padding: buttonPadding,
          shape: pill,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.ink,
          minimumSize: const Size.fromHeight(AppConstants.fieldHeight),
          padding: buttonPadding,
          side: BorderSide(color: p.switchTrackOff),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.ink,
          shape: pill,
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize:
              const Size(AppConstants.minTapTarget, AppConstants.minTapTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: pill,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              size: 20, color: selected ? p.ink : p.navInactive);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.ink : p.navInactive,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? p.gold : p.switchTrackOff),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? p.ink : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.background),
        side: BorderSide(color: p.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? p.ink : p.borderStrong),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.ink,
        disabledColor: p.surfaceSoft,
        side: BorderSide(color: p.border),
        shape: pill,
        showCheckmark: false,
        labelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: p.inkMuted),
        secondaryLabelStyle: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w600, color: p.background),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.hint,
        indicatorColor: p.ink,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkMuted,
        textColor: p.ink,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 11, color: p.hint),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        titleTextStyle: GoogleFonts.lora(
            fontSize: 20, fontWeight: FontWeight.w700, color: p.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.background : AppColors.ink,
        contentTextStyle: GoogleFonts.inter(
            fontSize: 13, color: isDark ? AppColors.ink : AppColors.background),
        actionTextColor: AppColors.goldLight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusInput)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.ink,
        linearTrackColor: p.surfaceSoft,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.ink,
        selectionColor: p.gold.withValues(alpha: 0.3),
        selectionHandleColor: p.gold,
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background : AppColors.ink,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        textStyle: GoogleFonts.inter(
            fontSize: 11, color: isDark ? AppColors.ink : AppColors.background),
      ),
    );
  }
}

/// Pushed routes slide in from the right while fading in.
class _SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: AppConstants.animCurve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.08, 0), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}
