import 'package:flutter/material.dart';

class AppTheme {
  // ============================================================
  // BRAND COLORS
  // ============================================================

  static const Color primary = Color(0xFF0B7A8F);
  static const Color primaryDark = Color(0xFF075E73);
  static const Color accentCyan = Color(0xFF12B8D4);
  static const Color accentBlue = Color(0xFF2563EB);

  static const Color iceBackground = Color(0xFFF0FDFA);

  // ============================================================
  // LIGHT COLORS
  // ============================================================

  static const Color lightBg = Color(0xFFF4F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF0F6F8);

  // Softer than the previous border
  static const Color lightBorder = Color(0xFFD5E1E6);
  static const Color lightBorderStrong = Color(0xFFB8CBD2);

  // ============================================================
  // DARK COLORS
  // ============================================================

  static const Color darkBg = Color(0xFF081522);
  static const Color darkSurface = Color(0xFF122334);
  static const Color darkSurfaceMuted = Color(0xFF0D1C2A);

  static const Color darkBorder = Color(0xFF304658);
  static const Color darkBorderStrong = Color(0xFF496477);

  // ============================================================
  // TEXT
  // ============================================================

  static const Color textPrimaryLight = Color(0xFF10212B);
  static const Color textSecondaryLight = Color(0xFF536873);

  static const Color textPrimaryDark = Color(0xFFF5FAFC);
  static const Color textSecondaryDark = Color(0xFFB5C5CE);

  // ============================================================
  // STATUS COLORS
  // ============================================================

  static const Color statusScheduled = Color(0xFF087EA4);
  static const Color statusCompleted = Color(0xFF16834A);
  static const Color statusCancelled = Color(0xFFD92D3A);
  static const Color statusInProgress = Color(0xFFD97706);

  // ============================================================
  // COMMON SHAPES
  // ============================================================

  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 18;
  static const double radiusXLarge = 22;

  // ============================================================
  // LIGHT THEME
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      fontFamily: 'Inter',

      scaffoldBackgroundColor: lightBg,

      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,

        secondary: accentCyan,
        onSecondary: Colors.white,

        surface: lightSurface,
        onSurface: textPrimaryLight,

        error: statusCancelled,
        onError: Colors.white,
      ),

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: textPrimaryLight,

        elevation: 0,
        scrolledUnderElevation: 0,

        surfaceTintColor: Colors.transparent,

        centerTitle: false,

        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: textPrimaryLight,
          letterSpacing: -0.3,
        ),

        iconTheme: IconThemeData(color: primary, size: 25),
      ),

      // ========================================================
      // CARDS
      // ========================================================
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,

        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),

          side: const BorderSide(color: lightBorder, width: 1),
        ),

        clipBehavior: Clip.antiAlias,
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: lightSurface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),

        labelStyle: const TextStyle(
          color: textSecondaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        floatingLabelStyle: const TextStyle(
          color: primary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),

        hintStyle: const TextStyle(color: textSecondaryLight, fontSize: 15),

        prefixIconColor: primary,
        suffixIconColor: textSecondaryLight,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: lightBorderStrong, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primary, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusCancelled, width: 1.5),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusCancelled, width: 2),
        ),
      ),

      // ========================================================
      // FILLED BUTTON
      // ========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,

          disabledBackgroundColor: lightBorder,
          disabledForegroundColor: textSecondaryLight,

          elevation: 0,

          minimumSize: const Size(0, 50),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),

          iconSize: 20,
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

          side: const BorderSide(color: primary, width: 1.3),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // DROPDOWN
      // ========================================================
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(lightSurface),

          elevation: const WidgetStatePropertyAll(8),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: lightBorder),
            ),
          ),
        ),

        textStyle: const TextStyle(
          color: textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // ICONS
      // ========================================================
      iconTheme: const IconThemeData(color: primary, size: 23),

      // ========================================================
      // SNACKBAR
      // ========================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryLight,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // DARK THEME
  // ============================================================

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      fontFamily: 'Inter',

      scaffoldBackgroundColor: darkBg,

      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        onPrimary: Colors.white,

        secondary: primary,
        onSecondary: Colors.white,

        surface: darkSurface,
        onSurface: textPrimaryDark,

        error: statusCancelled,
        onError: Colors.white,
      ),

      // ========================================================
      // APP BAR
      // ========================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: textPrimaryDark,

        elevation: 0,
        scrolledUnderElevation: 0,

        surfaceTintColor: Colors.transparent,

        centerTitle: false,

        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: textPrimaryDark,
          letterSpacing: -0.3,
        ),

        iconTheme: IconThemeData(color: accentCyan, size: 25),
      ),

      // ========================================================
      // CARDS
      // ========================================================
      cardTheme: CardThemeData(
        color: darkSurface,

        elevation: 0,

        margin: EdgeInsets.zero,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),

          side: const BorderSide(color: darkBorder, width: 1),
        ),

        clipBehavior: Clip.antiAlias,
      ),

      // ========================================================
      // INPUT FIELDS
      // ========================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: darkSurfaceMuted,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),

        labelStyle: const TextStyle(
          color: textSecondaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        floatingLabelStyle: const TextStyle(
          color: accentCyan,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),

        hintStyle: const TextStyle(color: textSecondaryDark, fontSize: 15),

        prefixIconColor: accentCyan,
        suffixIconColor: textSecondaryDark,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: darkBorderStrong, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusCancelled, width: 1.5),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: statusCancelled, width: 2),
        ),
      ),

      // ========================================================
      // FILLED BUTTON
      // ========================================================
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,

          disabledBackgroundColor: darkBorder,
          disabledForegroundColor: textSecondaryDark,

          elevation: 0,

          minimumSize: const Size(0, 50),

          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),

          iconSize: 20,
        ),
      ),

      // ========================================================
      // OUTLINED BUTTON
      // ========================================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,

          minimumSize: const Size(0, 48),

          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

          side: const BorderSide(color: accentCyan, width: 1.3),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),

          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // TEXT BUTTON
      // ========================================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentCyan,

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // DROPDOWN
      // ========================================================
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(darkSurface),

          elevation: const WidgetStatePropertyAll(10),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: darkBorder),
            ),
          ),
        ),

        textStyle: const TextStyle(
          color: textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ========================================================
      // DIVIDERS
      // ========================================================
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ========================================================
      // ICONS
      // ========================================================
      iconTheme: const IconThemeData(color: accentCyan, size: 23),

      // ========================================================
      // SNACKBAR
      // ========================================================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurface,

        contentTextStyle: const TextStyle(
          color: textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}

// ================================================================
// GLOBAL CLINICAL HEADER
// ================================================================

Widget buildClinicalHeader(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    width: double.infinity,

    padding: const EdgeInsets.all(24),

    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? const [Color(0xFF164E63), Color(0xFF075985), Color(0xFF0F766E)]
            : const [Color(0xFF075E73), Color(0xFF0B7A8F), Color(0xFF0891B2)],

        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),

      borderRadius: BorderRadius.circular(20),

      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withValues(alpha: isDark ? 0.30 : 0.18),

          blurRadius: 22,

          offset: const Offset(0, 8),
        ),
      ],
    ),

    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,

          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),

            borderRadius: BorderRadius.circular(15),

            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),

          child: Icon(icon, color: Colors.white, size: 28),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,

                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ================================================================
// GLOBAL DETAIL CARD
// ================================================================

Widget buildDetailCard(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  Color iconAccent = AppTheme.primary,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    width: double.infinity,

    margin: const EdgeInsets.only(bottom: 12),

    padding: const EdgeInsets.all(16),

    decoration: BoxDecoration(
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,

      borderRadius: BorderRadius.circular(14),

      border: Border.all(
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        width: 1,
      ),

      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.035),

          blurRadius: 10,

          offset: const Offset(0, 3),
        ),
      ],
    ),

    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,

          decoration: BoxDecoration(
            color: iconAccent.withValues(alpha: isDark ? 0.18 : 0.09),

            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: iconAccent.withValues(alpha: isDark ? 0.25 : 0.12),
            ),
          ),

          child: Icon(icon, color: iconAccent, size: 21),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,

                  fontSize: 12,

                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value.isEmpty ? '--' : value,

                style: TextStyle(
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,

                  fontSize: 15,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
