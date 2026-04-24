import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP DESIGN TOKENS — Single source of truth for all screens
// ─────────────────────────────────────────────────────────────────────────────

/// Spacing scale: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48
class AppSpacing {
  static const double xs    = 4;
  static const double sm    = 8;
  static const double md    = 12;
  static const double base  = 16;
  static const double lg    = 20;
  static const double xl    = 24;
  static const double xxl   = 32;
  static const double xxxl  = 48;

  /// Standard horizontal screen padding
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets screen  = EdgeInsets.symmetric(horizontal: base, vertical: base);
  static const EdgeInsets card    = EdgeInsets.all(base);
  static const EdgeInsets cardSm  = EdgeInsets.all(md);
}

/// Border radius scale
class AppRadius {
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double full = 999;

  static BorderRadius get smR  => BorderRadius.circular(sm);
  static BorderRadius get mdR  => BorderRadius.circular(md);
  static BorderRadius get lgR  => BorderRadius.circular(lg);
  static BorderRadius get xlR  => BorderRadius.circular(xl);
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS COLORS — Consistent across ALL screens (light + dark)
// ─────────────────────────────────────────────────────────────────────────────
class AppStatus {
  static const Color newColor        = Color(0xFFF59E0B); // amber
  static const Color inProgressColor = Color(0xFF3B82F6); // blue
  static const Color onHoldColor     = Color(0xFF8B5CF6); // violet
  static const Color resolvedColor   = Color(0xFF10B981); // emerald
  static const Color closedColor     = Color(0xFF6B7280); // gray
  static const Color rejectedColor   = Color(0xFFEF4444); // red

  static Color fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':          return newColor;
      case 'in_progress':  return inProgressColor;
      case 'on_hold':      return onHoldColor;
      case 'resolved':     return resolvedColor;
      case 'closed':       return closedColor;
      case 'rejected':     return rejectedColor;
      default:             return closedColor;
    }
  }

  static IconData iconFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':          return Icons.fiber_new_rounded;
      case 'in_progress':  return Icons.sync_rounded;
      case 'on_hold':      return Icons.pause_circle_rounded;
      case 'resolved':     return Icons.check_circle_rounded;
      case 'closed':       return Icons.lock_rounded;
      case 'rejected':     return Icons.cancel_rounded;
      default:             return Icons.help_rounded;
    }
  }

  static String labelFromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':          return 'New';
      case 'in_progress':  return 'In Progress';
      case 'on_hold':      return 'On Hold';
      case 'resolved':     return 'Resolved';
      case 'closed':       return 'Closed';
      case 'rejected':     return 'Rejected';
      default:             return status;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Linear interpolation between two doubles. Used by ThemeExtension lerp methods.
double _ld(double a, double b, double t) => a + (b - a) * t;

// ─────────────────────────────────────────────────────────────────────────────
// THEME EXTENSION — Spacing & effects injected via ThemeData
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens> {
  const AppSpacingTokens({
    required this.xs, required this.sm, required this.md,
    required this.lg, required this.xl, required this.xxl,
  });
  final double xs, sm, md, lg, xl, xxl;

  @override
  AppSpacingTokens copyWith({
    double? xs, double? sm, double? md,
    double? lg, double? xl, double? xxl,
  }) => AppSpacingTokens(
    xs: xs ?? this.xs, sm: sm ?? this.sm, md: md ?? this.md,
    lg: lg ?? this.lg, xl: xl ?? this.xl, xxl: xxl ?? this.xxl,
  );

  @override
  AppSpacingTokens lerp(ThemeExtension<AppSpacingTokens>? other, double t) {
    if (other is! AppSpacingTokens) return this;
    return AppSpacingTokens(
      xs: _ld(xs, other.xs, t), sm: _ld(sm, other.sm, t), md: _ld(md, other.md, t),
      lg: _ld(lg, other.lg, t), xl: _ld(xl, other.xl, t), xxl: _ld(xxl, other.xxl, t),
    );
  }
}

@immutable
class AppEffectsTokens extends ThemeExtension<AppEffectsTokens> {
  const AppEffectsTokens({
    required this.radiusSm, required this.radiusMd, required this.radiusLg,
    required this.cardElevation, required this.panelShadow,
  });
  final double radiusSm, radiusMd, radiusLg, cardElevation;
  final List<BoxShadow> panelShadow;

  @override
  AppEffectsTokens copyWith({
    double? radiusSm, double? radiusMd, double? radiusLg,
    double? cardElevation, List<BoxShadow>? panelShadow,
  }) => AppEffectsTokens(
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    cardElevation: cardElevation ?? this.cardElevation,
    panelShadow: panelShadow ?? this.panelShadow,
  );

  @override
  AppEffectsTokens lerp(ThemeExtension<AppEffectsTokens>? other, double t) {
    if (other is! AppEffectsTokens) return this;
    return AppEffectsTokens(
      radiusSm: _ld(radiusSm, other.radiusSm, t),
      radiusMd: _ld(radiusMd, other.radiusMd, t),
      radiusLg: _ld(radiusLg, other.radiusLg, t),
      cardElevation: _ld(cardElevation, other.cardElevation, t),
      panelShadow: BoxShadow.lerpList(panelShadow, other.panelShadow, t) ?? panelShadow,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN THEME
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  // Primary palette — blue civic identity
  static const Color primary     = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight= Color(0xFF1976D2);
  static const Color accent      = Color(0xFF0288D1);
  static const Color success     = Color(0xFF2E7D32);
  static const Color warning     = Color(0xFFE65100);
  static const Color error       = Color(0xFFC62828);

  // Neutral palette
  static const Color background  = Color(0xFFF4F6F9);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color surfaceAlt  = Color(0xFFF0F4FA);
  static const Color border      = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecond  = Color(0xFF4A5568);
  static const Color textHint    = Color(0xFFA0AEC0);
  static const Color divider     = Color(0xFFEDF2F7);

  static const AppSpacingTokens spacing = AppSpacingTokens(
    xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32,
  );

  static final AppEffectsTokens effects = AppEffectsTokens(
    radiusSm: AppRadius.sm,
    radiusMd: AppRadius.md,
    radiusLg: AppRadius.lg,
    cardElevation: 1,
    panelShadow: [
      BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 12, offset: const Offset(0, 4)),
    ],
  );

  // ── Light Theme ──────────────────────────────────────────────────────────
  static final ThemeData light = _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      tertiary: Color(0xFFED6C02),
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    scaffoldBg: background,
    appBarBg: primary,
    appBarFg: Colors.white,
    cardColor: surface,
    inputFill: surface,
    divColor: divider,
  );

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: Color(0xFF42A5F5),
      secondary: Color(0xFF4DD0E1),
      tertiary: Color(0xFFFFB74D),
      surface: Color(0xFF1A1A2E),
      error: Color(0xFFEF5350),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFE2E8F0),
      onError: Colors.black,
    ),
    scaffoldBg: const Color(0xFF0F0F1A),
    appBarBg: const Color(0xFF1A1A2E),
    appBarFg: const Color(0xFFE2E8F0),
    cardColor: const Color(0xFF1A1A2E),
    inputFill: const Color(0xFF242438),
    divColor: const Color(0xFF2D2D4A),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color scaffoldBg,
    required Color appBarBg,
    required Color appBarFg,
    required Color cardColor,
    required Color inputFill,
    required Color divColor,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      scaffoldBackgroundColor: scaffoldBg,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        foregroundColor: appBarFg,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha:0.1),
        centerTitle: true,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: appBarFg,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: appBarFg, size: 24),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgR,
          side: BorderSide(color: divColor),
        ),
        margin: EdgeInsets.zero,
        color: cardColor,
      ),

      // ── Input Fields ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
        constraints: const BoxConstraints(minHeight: 52),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdR,
          borderSide: BorderSide(color: divColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdR,
          borderSide: BorderSide(color: divColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdR,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdR,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdR,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : textSecond),
        hintStyle: TextStyle(color: textHint),
        errorStyle: TextStyle(color: scheme.error, fontSize: 12),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smR),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Typography ───────────────────────────────────────────────────────
      textTheme: _buildTextTheme(isDark),

      // ── Navigation ───────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: isDark ? const Color(0xFF6B7280) : textHint,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: divColor, thickness: 1, space: 1),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
        minVerticalPadding: AppSpacing.sm,
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smR),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        elevation: 8,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdR),
        contentTextStyle: const TextStyle(fontSize: 14),
      ),

      extensions: [spacing, effects],
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final base = isDark ? Colors.white : textPrimary;
    final sub  = isDark ? const Color(0xFF94A3B8) : textSecond;

    return TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: base, height: 1.2),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: base, height: 1.2),
      displaySmall:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: base, height: 1.3),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: base, height: 1.3),
      headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: base, height: 1.4),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base, height: 1.4),
      titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: base),
      titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: base),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: base, height: 1.6),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: base, height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: sub, height: 1.5),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: base),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sub),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: sub),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUILD CONTEXT EXTENSIONS
// ─────────────────────────────────────────────────────────────────────────────
extension AppThemeContext on BuildContext {
  AppSpacingTokens get appSpacing => Theme.of(this).extension<AppSpacingTokens>() ?? AppTheme.spacing;
  AppEffectsTokens get appEffects => Theme.of(this).extension<AppEffectsTokens>() ?? AppTheme.effects;
  ColorScheme      get colors     => Theme.of(this).colorScheme;
  TextTheme        get textStyles => Theme.of(this).textTheme;
  bool             get isDark     => Theme.of(this).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKWARD-COMPATIBLE aliases for screens that used dsXxx globals
// These delegate to AppTheme constants so screens don't need big rewrites.
// ─────────────────────────────────────────────────────────────────────────────
const Color dsBackground = Color(0xFF0B1628);
const Color dsSurface = Color(0xFF132136);
const Color dsSurfaceAlt = Color(0xFF1A2F4A);
const Color dsAccent = Color(0xFF3B82F6);
const Color dsAccentSoft = Color(0xFF60A5FA);
const Color dsAccentDim = Color(0xFF1D4ED8);
const Color dsTextPrimary = Color(0xFFE2E8F0);
const Color dsTextSecondary = Color(0xFF94A3B8);
const Color dsBorder = Color(0xFF1E3A5F);

BoxDecoration dsPanelDecoration({Color? color, double radius = 16}) =>
    BoxDecoration(
      color: color ?? dsSurfaceAlt,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: dsBorder, width: 1),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.12), blurRadius: 12, offset: const Offset(0, 4))],
    );

InputDecoration dsFormFieldDecoration({required String label}) =>
    InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: dsTextSecondary),
      filled: true,
      fillColor: dsSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: AppRadius.mdR, borderSide: BorderSide(color: dsBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdR, borderSide: BorderSide(color: dsBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdR, borderSide: BorderSide(color: dsAccent, width: 2)),
    );

TextStyle dsHeadingStyle([double size = 18]) =>
    TextStyle(color: dsTextPrimary, fontSize: size, fontWeight: FontWeight.w700);

TextStyle dsSubtitleStyle([double size = 13]) =>
    TextStyle(color: dsTextSecondary, fontSize: size, fontWeight: FontWeight.w500);

// Note: dart:ui exposes lerpDouble() via flutter/material.dart — use that directly in screens.