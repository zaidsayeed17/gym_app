import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Lumina Core Color Tokens ───
  static const Color primary = Color(0xFF006C49);
  static const Color primaryContainer = Color(0xFF10B981);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF00422B);
  static const Color onPrimaryFixedVariant = Color(0xFF005236);

  static const Color secondary = Color(0xFF5D5D6E);
  static const Color secondaryContainer = Color(0xFFE0DDF2);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF626173);

  static const Color tertiary = Color(0xFFA43A3A);
  static const Color tertiaryContainer = Color(0xFFFC7C78);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF711419);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color surface = Color(0xFFF8F9FB);
  static const Color surfaceBright = Color(0xFFF8F9FB);
  static const Color surfaceDim = Color(0xFFD9DADC);
  static const Color surfaceContainer = Color(0xFFEDEEF0);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainerHigh = Color(0xFFE7E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3C4A42);

  static const Color outline = Color(0xFF6C7A71);
  static const Color outlineVariant = Color(0xFFBBCABF);

  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F3);
  static const Color inversePrimary = Color(0xFF4EDEA3);

  static const Color background = Color(0xFFF8F9FB);
  static const Color onBackground = Color(0xFF191C1E);

  // ─── Semantic Colors ───
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusActiveBg = Color(0xFFDCFCE7);
  static const Color statusActiveText = Color(0xFF166534);
  static const Color statusExpiring = Color(0xFFA43A3A);
  static const Color statusExpiringBg = Color(0xFFFFDAD7);
  static const Color statusExpired = Color(0xFFBA1A1A);
  static const Color statusExpiredBg = Color(0xFFFFDAD6);

  // ─── Elevation / Shadows ───
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 25,
      offset: const Offset(0, 20),
    ),
  ];

  // ─── Spacing Tokens ───
  static const double baseUnit = 4;
  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 24;
  static const double gutter = 24;
  static const double containerPadding = 32;
  static const double sidebarWidth = 260;

  // ─── Border Radius ───
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 9999;

  // ─── Typography Styles ───
  static TextStyle get displayStat => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.72,
    height: 44 / 36,
    color: onSurface,
  );

  static TextStyle get headlineLg => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    height: 32 / 24,
    color: onSurface,
  );

  static TextStyle get headlineMd => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: onSurface,
  );

  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: onSurface,
  );

  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: onSurface,
  );

  static TextStyle get labelSm => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 16 / 12,
    color: onSurfaceVariant,
  );

  // ─── ThemeData ───
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiary: onTertiary,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        inversePrimary: inversePrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onPrimaryContainer,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: onPrimaryContainer, size: 24);
          }
          return const IconThemeData(color: onSurfaceVariant, size: 24);
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineVariant,
        thickness: 1,
      ),
    );
  }
}
