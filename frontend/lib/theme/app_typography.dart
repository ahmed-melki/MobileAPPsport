import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Syne = titres sportifs / Manrope = lecture.
abstract final class AppTypography {
  static TextTheme textTheme() {
    final display = GoogleFonts.syneTextTheme();
    final body = GoogleFonts.manropeTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 0.95,
        letterSpacing: -1.6,
        color: AppColors.textPrimary,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.8,
        color: AppColors.textPrimary,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.textPrimary,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      titleMedium: body.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textPrimary,
      ),
      titleSmall: body.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.textPrimary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
      ),
      labelMedium: body.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      ),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textTertiary,
      ),
    );
  }
}
