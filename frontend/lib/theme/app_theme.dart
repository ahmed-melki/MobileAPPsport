import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final textTheme = AppTypography.textTheme();
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.volt,
      onPrimary: AppColors.textOnVolt,
      secondary: AppColors.cyan,
      onSecondary: AppColors.textOnVolt,
      tertiary: AppColors.violet,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.coral,
      onError: AppColors.textPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.scaffold,
      canvasColor: AppColors.scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lgAll,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.volt,
          foregroundColor: AppColors.textOnVolt,
          disabledBackgroundColor: AppColors.surfaceElevated,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: const BorderSide(color: AppColors.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.volt,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.voltGlow,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        floatingLabelStyle: textTheme.labelLarge?.copyWith(color: AppColors.volt),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.volt, width: 1.4),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedItemColor: AppColors.volt,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
