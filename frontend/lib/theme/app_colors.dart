import 'package:flutter/material.dart';

/// Palette APEX — dark athletic, énergie volt.
/// Tous les modules doivent puiser ici (jamais de couleurs hardcodées).
abstract final class AppColors {
  static const voidBlack = Color(0xFF05060A);
  static const scaffold = Color(0xFF0B0D12);
  static const surface = Color(0xFF141821);
  static const surfaceElevated = Color(0xFF1C2230);
  static const surfaceMuted = Color(0xFF10141C);

  static const border = Color(0xFF2A3142);
  static const borderStrong = Color(0xFF3A4358);

  /// Accent principal — performance, CTAs, highlights.
  static const volt = Color(0xFFD6FF2F);
  static const voltDim = Color(0xFFA8C924);
  static const voltGlow = Color(0x33D6FF2F);

  /// Accents secondaires (données, récupération).
  static const cyan = Color(0xFF3EF0E0);
  static const coral = Color(0xFFFF5B3C);
  static const violet = Color(0xFFB39CFF);
  static const mint = Color(0xFF6CFFB0);
  static const amber = Color(0xFFFFC84A);

  static const textPrimary = Color(0xFFF4F5F8);
  static const textSecondary = Color(0xFF9AA3B5);
  static const textTertiary = Color(0xFF6B7386);
  static const textOnVolt = Color(0xFF0B0D12);

  static const overlay = Color(0x9905060A);
}
