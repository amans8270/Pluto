import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Pluto Brand Colors ────────────────────────────────────────────────────────
class PlutoColors {
  PlutoColors._();

  // Dating mode
  static const Color dating = Color(0xFFFF4D6D);
  static const Color datingLight = Color(0xFFFF8096);
  static const Color datingDark = Color(0xFFD63055);

  // TravelBuddy mode
  static const Color travel = Color(0xFF00BFA6);
  static const Color travelLight = Color(0xFF00D4B8);
  static const Color travelDark = Color(0xFF009688);

  // BFF mode
  static const Color bff = Color(0xFFF5A623);
  static const Color bffLight = Color(0xFFFFBA4D);
  static const Color bffDark = Color(0xFFE09000);

  // Neutrals
  static const Color dark = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkSurface = Color(0xFF0F3460);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B8C1);

  // Utility
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color dividerDark = Color(0xFF374151);
  static const Color online = Color(0xFF22C55E);

  // Mode gradient maps
  static Color modeColor(String mode) {
    switch (mode.toUpperCase()) {
      case 'DATE':
        return dating;
      case 'TRAVELBUDDY':
        return travel;
      case 'BFF':
        return bff;
      default:
        return dating;
    }
  }
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class PlutoTextStyles {
  PlutoTextStyles._();

  static final String? _fontFamily = GoogleFonts.outfit().fontFamily;

  static final TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  static final TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static final TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static final TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static final TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

// ─── Theme Builder ────────────────────────────────────────────────────────────
class PlutoTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Outfit',
      colorScheme: const ColorScheme.light(
        primary: PlutoColors.dating,
        secondary: PlutoColors.travel,
        tertiary: PlutoColors.bff,
        surface: PlutoColors.white,
        onPrimary: PlutoColors.white,
        onSurface: PlutoColors.textPrimaryLight,
        outline: PlutoColors.divider,
      ),
      scaffoldBackgroundColor: PlutoColors.offWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: PlutoColors.white,
        foregroundColor: PlutoColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: PlutoTextStyles.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: PlutoColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PlutoColors.dating,
          foregroundColor: PlutoColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: PlutoTextStyles.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlutoColors.dating,
          side: const BorderSide(color: PlutoColors.dating, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: PlutoTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PlutoColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PlutoColors.dating, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
            color: PlutoColors.textSecondaryLight, fontFamily: 'Outfit'),
      ),
      dividerTheme: const DividerThemeData(
        color: PlutoColors.divider,
        thickness: 1,
        space: 0,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Outfit',
      colorScheme: const ColorScheme.dark(
        primary: PlutoColors.dating,
        secondary: PlutoColors.travel,
        tertiary: PlutoColors.bff,
        surface: PlutoColors.darkCard,
        onPrimary: PlutoColors.white,
        onSurface: PlutoColors.textPrimaryDark,
        outline: PlutoColors.dividerDark,
      ),
      scaffoldBackgroundColor: PlutoColors.dark,
      appBarTheme: AppBarTheme(
        backgroundColor: PlutoColors.dark,
        foregroundColor: PlutoColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: PlutoTextStyles.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: PlutoColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PlutoColors.dating,
          foregroundColor: PlutoColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: PlutoTextStyles.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlutoColors.dating,
          side: const BorderSide(color: PlutoColors.dating, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: PlutoTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PlutoColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: PlutoColors.dating, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
            color: PlutoColors.textSecondaryDark, fontFamily: 'Outfit'),
      ),
      dividerTheme: const DividerThemeData(
        color: PlutoColors.dividerDark,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
