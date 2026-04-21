import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const heroBg          = Color(0xFF1a3d1f);
  static const primary         = Color(0xFF2e7d32);
  static const primaryLight    = Color(0xFF4caf50);
  static const primarySurface  = Color(0xFFf1f8e9);
  static const primaryMuted    = Color(0xFFc8e6c9);
  static const heroSubtext     = Color(0xFFa5d6a7);
  static const white           = Color(0xFFffffff);
  static const background      = Color(0xFFf9f9f7);
  static const surface         = Color(0xFFf4f4f2);
  static const border          = Color(0xFFe0e0e0);
  static const textPrimary     = Color(0xFF1c1c1c);
  static const textSecondary   = Color(0xFF6b6b6b);
  static const textMuted       = Color(0xFFa0a0a0);
  static const danger          = Color(0xFFbf360c);
  static const dangerSurface   = Color(0xFFfbe9e7);
  static const dangerBorder    = Color(0xFFff8a65);
  static const warning         = Color(0xFFe65100);
  static const warningSurface  = Color(0xFFfff8e1);
  static const warningBorder   = Color(0xFFffb300);
  static const success         = Color(0xFF2e7d32);
  static const successSurface  = Color(0xFFf1f8e9);
  static const successBorder   = Color(0xFF66bb6a);
  static const info            = Color(0xFF1565c0);
  static const infoSurface     = Color(0xFFe3f2fd);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.dmSansTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.heroBg,
      foregroundColor: AppColors.primaryMuted,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    ),
  );
}
