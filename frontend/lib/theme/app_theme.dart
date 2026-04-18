import 'package:flutter/material.dart';

@immutable
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens> {
  const AppSpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  @override
  AppSpacingTokens copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return AppSpacingTokens(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  AppSpacingTokens lerp(ThemeExtension<AppSpacingTokens>? other, double t) {
    if (other is! AppSpacingTokens) return this;
    return AppSpacingTokens(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
    );
  }
}

@immutable
class AppEffectsTokens extends ThemeExtension<AppEffectsTokens> {
  const AppEffectsTokens({
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.cardElevation,
    required this.panelShadow,
  });

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double cardElevation;
  final List<BoxShadow> panelShadow;

  @override
  AppEffectsTokens copyWith({
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? cardElevation,
    List<BoxShadow>? panelShadow,
  }) {
    return AppEffectsTokens(
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      cardElevation: cardElevation ?? this.cardElevation,
      panelShadow: panelShadow ?? this.panelShadow,
    );
  }

  @override
  AppEffectsTokens lerp(ThemeExtension<AppEffectsTokens>? other, double t) {
    if (other is! AppEffectsTokens) return this;
    return AppEffectsTokens(
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t),
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t),
      panelShadow: BoxShadow.lerpList(panelShadow, other.panelShadow, t) ?? panelShadow,
    );
  }
}

@immutable
class AppDashboardTokens extends ThemeExtension<AppDashboardTokens> {
  const AppDashboardTokens({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.accentSoft,
    required this.accentDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color accentSoft;
  final Color accentDim;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  @override
  AppDashboardTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? accent,
    Color? accentSoft,
    Color? accentDim,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
  }) {
    return AppDashboardTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentDim: accentDim ?? this.accentDim,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
    );
  }

  @override
  AppDashboardTokens lerp(ThemeExtension<AppDashboardTokens>? other, double t) {
    if (other is! AppDashboardTokens) return this;
    return AppDashboardTokens(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t) ?? surfaceAlt,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      accentDim: Color.lerp(accentDim, other.accentDim, t) ?? accentDim,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      border: Color.lerp(border, other.border, t) ?? border,
    );
  }
}

class AppTheme {
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF42A5F5);
  static const Color accentColor = Color(0xFFFF7043);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static const Color onBackgroundColor = Color(0xFF000000);
  static const Color onSurfaceColor = Color(0xFF000000);
  static const Color greyColor = Color(0xFF9E9E9E);
  static const Color lightGreyColor = Color(0xFFEEEEEE);

  static const AppSpacingTokens spacing = AppSpacingTokens(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xxl: 32,
  );

  static final AppEffectsTokens effects = AppEffectsTokens(
    radiusSm: 10,
    radiusMd: 12,
    radiusLg: 16,
    cardElevation: 2,
    panelShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.22),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static const AppDashboardTokens dashboard = AppDashboardTokens(
    background: Color(0xFF081623),
    surface: Color(0xFF10243A),
    surfaceAlt: Color(0xFF132A46),
    accent: Color(0xFF00E5FF),
    accentSoft: Color(0xFF54C7FF),
    accentDim: Color(0xFF0097A7),
    textPrimary: Color(0xFFE8F4FD),
    textSecondary: Color(0xFF8BA3BE),
    border: Color(0xFF1C3460),
  );

  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: onBackgroundColor,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: onBackgroundColor,
  );
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: onBackgroundColor,
  );
  static const TextStyle subtitle1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: onBackgroundColor,
  );
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: onBackgroundColor,
  );
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onBackgroundColor,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: greyColor,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: onPrimaryColor,
  );

  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: onPrimaryColor,
      onSecondary: onSecondaryColor,
      onSurface: onSurfaceColor,
      onError: onPrimaryColor,
    ),
    scaffoldBackground: backgroundColor,
    appBarBackground: primaryColor,
    appBarForeground: onPrimaryColor,
    cardColor: surfaceColor,
    inputFillColor: surfaceColor,
    dividerColor: lightGreyColor,
    textTheme: const TextTheme(
      displayLarge: headline1,
      displayMedium: headline2,
      displaySmall: headline3,
      titleMedium: subtitle1,
      bodyLarge: bodyText1,
      bodyMedium: bodyText2,
      labelSmall: caption,
    ),
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: Color(0xFF121212),
      error: errorColor,
      onPrimary: onPrimaryColor,
      onSecondary: onSecondaryColor,
      onSurface: Color(0xFFFFFFFF),
      onError: onPrimaryColor,
    ),
    scaffoldBackground: const Color(0xFF000000),
    appBarBackground: const Color(0xFF121212),
    appBarForeground: const Color(0xFFFFFFFF),
    cardColor: const Color(0xFF1E1E1E),
    inputFillColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF424242),
    textTheme: TextTheme(
      displayLarge: headline1.copyWith(color: Colors.white),
      displayMedium: headline2.copyWith(color: Colors.white),
      displaySmall: headline3.copyWith(color: Colors.white),
      titleMedium: subtitle1.copyWith(color: Colors.white),
      bodyLarge: bodyText1.copyWith(color: Colors.white),
      bodyMedium: bodyText2.copyWith(color: Colors.white),
      labelSmall: caption.copyWith(color: const Color(0xFFBDBDBD)),
    ),
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color cardColor,
    required Color inputFillColor,
    required Color dividerColor,
    required TextTheme textTheme,
  }) {
    return ThemeData(
      brightness: brightness,
      primaryColor: colorScheme.primary,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: effects.cardElevation,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: appBarForeground,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: effects.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effects.radiusMd),
        ),
        margin: const EdgeInsets.all(8),
        color: cardColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effects.radiusMd),
          borderSide: const BorderSide(color: greyColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effects.radiusMd),
          borderSide: const BorderSide(color: greyColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effects.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(effects.radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effects.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: buttonText.copyWith(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: buttonText.copyWith(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effects.radiusMd),
          ),
        ),
      ),
      textTheme: textTheme,
      iconTheme: IconThemeData(
        color: colorScheme.primary,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      extensions: [spacing, effects, dashboard],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSpacingTokens get appSpacing => Theme.of(this).extension<AppSpacingTokens>() ?? AppTheme.spacing;

  AppEffectsTokens get appEffects => Theme.of(this).extension<AppEffectsTokens>() ?? AppTheme.effects;

  AppDashboardTokens get appDashboard => Theme.of(this).extension<AppDashboardTokens>() ?? AppTheme.dashboard;
}

// Backward-compatible aliases for existing screen-level migration.
Color get dsBackground => AppTheme.dashboard.background;
Color get dsSurface => AppTheme.dashboard.surface;
Color get dsSurfaceAlt => AppTheme.dashboard.surfaceAlt;
Color get dsAccent => AppTheme.dashboard.accent;
Color get dsAccentSoft => AppTheme.dashboard.accentSoft;
Color get dsAccentDim => AppTheme.dashboard.accentDim;
Color get dsTextPrimary => AppTheme.dashboard.textPrimary;
Color get dsTextSecondary => AppTheme.dashboard.textSecondary;
Color get dsBorder => AppTheme.dashboard.border;

BoxDecoration dsPanelDecoration({Color color = const Color(0xFF132A46), double radius = 18}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: dsAccent.withOpacity(0.14), width: 1),
    boxShadow: AppTheme.effects.panelShadow,
  );
}

InputDecoration dsFormFieldDecoration({required String label}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF8BA3BE)),
    filled: true,
    fillColor: dsSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
      borderSide: const BorderSide(color: Color(0xFF1C3460)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
      borderSide: const BorderSide(color: Color(0xFF1C3460)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.effects.radiusLg),
      borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 2),
    ),
  );
}

TextStyle dsHeadingStyle([double size = 18]) {
  return TextStyle(
    color: dsTextPrimary,
    fontSize: size,
    fontWeight: FontWeight.w700,
  );
}

TextStyle dsSubtitleStyle([double size = 14]) {
  return TextStyle(
    color: dsTextSecondary,
    fontSize: size,
    fontWeight: FontWeight.w500,
  );
}

Widget dsSectionTitle(String title, {IconData? icon}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (icon != null) Icon(icon, color: dsAccent, size: 18),
      if (icon != null) const SizedBox(width: 8),
      Text(title, style: dsHeadingStyle(16)),
      const Spacer(),
      Container(height: 1, width: 60, color: dsAccentSoft.withOpacity(0.5)),
    ],
  );
}

double lerpDouble(num a, num b, double t) => (a + (b - a) * t).toDouble();
