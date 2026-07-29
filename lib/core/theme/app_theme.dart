import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Executive Clinical Color Palette
  static const Color primaryColor = Color(0xFF0F4C81); // Executive Deep Blue
  static const Color primaryLightColor = Color(0xFF38BDF8); // Bright Sky Blue for Dark Mode
  static const Color secondaryColor = Color(0xFF0D9488); // Clinical Emerald/Teal
  static const Color secondaryLightColor = Color(0xFF2DD4BF);
  static const Color accentColor = Color(0xFFF59E0B); // Warm Gold / Amber
  static const Color errorColor = Color(0xFFEF4444); // Crimson Alert
  static const Color successColor = Color(0xFF10B981); // Emerald Success

  // Neutral Colors (Light)
  static const Color backgroundColor = Color(0xFFF8FAFC); // Slate 50 clean background
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF0F172A); // Slate 900 high contrast
  static const Color textSecondaryColor = Color(0xFF64748B); // Slate 500 label
  static const Color textMutedColor = Color(0xFF94A3B8); // Slate 400 helper
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200 crisp border
  static const Color dividerColor = Color(0xFFF1F5F9); // Slate 100 subtle line

  // Dark Mode Palette (Rich Slate Navy)
  static const Color darkBackgroundColor = Color(0xFF0B132B); // Rich Deep Navy Background
  static const Color darkSurfaceColor = Color(0xFF1C2541); // Elevated Navy Surface
  static const Color darkCardColor = Color(0xFF1C2541); // Card background in dark mode
  static const Color darkTextPrimaryColor = Color(0xFFF8FAFC); // Crisp Light Text
  static const Color darkTextSecondaryColor = Color(0xFF94A3B8); // Muted Light Text
  static const Color darkBorderColor = Color(0xFF2E3A59); // Subtle Dark Border

  // Dynamic Theme Helpers
  static Color surfaceColorOf(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color cardColorOf(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  static Color backgroundColorOf(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color borderColorOf(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  static Color textPrimaryColorOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkTextPrimaryColor : textPrimaryColor;
  }

  static Color textSecondaryColorOf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkTextSecondaryColor : textSecondaryColor;
  }

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  // Role Colors
  static const Color patientColor = Color(0xFF0F4C81);
  static const Color doctorColor = Color(0xFF0D9488);
  static const Color adminColor = Color(0xFF7C3AED);

  // Status Colors
  static const Color upcomingColor = Color(0xFF3B82F6);
  static const Color completedColor = Color(0xFF10B981);
  static const Color cancelledColor = Color(0xFFEF4444);
  static const Color pendingColor = Color(0xFFF59E0B);

  // Premium Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F4C81), Color(0xFF1E88E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient doctorGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F4C81), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Presets
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> primaryGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryColor,
        outline: borderColor,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: textPrimaryColor,
            letterSpacing: -0.8,
            height: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: textPrimaryColor,
            letterSpacing: -0.6,
          ),
          displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimaryColor,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimaryColor,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textSecondaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textPrimaryColor,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: textSecondaryColor,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryColor,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: textPrimaryColor,
        ),
        iconTheme: const IconThemeData(color: textPrimaryColor, size: 22),
        actionsIconTheme: const IconThemeData(color: textPrimaryColor, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondaryColor,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textMutedColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondaryColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 24);
          }
          return const IconThemeData(color: textSecondaryColor, size: 24);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 12,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 12,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLightColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryLightColor,
        secondary: secondaryLightColor,
        error: errorColor,
        surface: darkSurfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimaryColor,
        outline: darkBorderColor,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: darkTextPrimaryColor,
            letterSpacing: -0.8,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: darkTextPrimaryColor,
            letterSpacing: -0.6,
          ),
          displaySmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkTextPrimaryColor,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkTextPrimaryColor,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkTextPrimaryColor,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextPrimaryColor,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkTextPrimaryColor,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: darkTextSecondaryColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: darkTextPrimaryColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: darkTextPrimaryColor,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkTextSecondaryColor,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkTextPrimaryColor,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondaryColor,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimaryColor,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: darkTextPrimaryColor,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimaryColor, size: 22),
        actionsIconTheme: const IconThemeData(color: darkTextPrimaryColor, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightColor,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLightColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: darkBorderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLightColor, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkTextSecondaryColor,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkTextSecondaryColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceColor,
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        elevation: 8,
        indicatorColor: primaryLightColor.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryLightColor,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondaryColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLightColor, size: 24);
          }
          return const IconThemeData(color: darkTextSecondaryColor, size: 24);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLightColor,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorderColor,
        thickness: 1,
      ),
    );
  }
}
