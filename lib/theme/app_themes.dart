// lib/theme/app_themes.dart
import 'package:flutter/material.dart';

// ── Colour seeds for each named theme ────────────────────────────────────
const _seedBlue   = Color(0xFF1565C0);
const _seedTeal   = Color(0xFF00796B);
const _seedPurple = Color(0xFF6A1B9A);
const _seedAmber  = Color(0xFFE65100);

enum AppThemeChoice { systemBlue, systemTeal, systemPurple, systemAmber }

extension AppThemeChoiceLabel on AppThemeChoice {
  String get label => switch (this) {
        AppThemeChoice.systemBlue   => 'Ocean Blue',
        AppThemeChoice.systemTeal   => 'Forest Teal',
        AppThemeChoice.systemPurple => 'Deep Purple',
        AppThemeChoice.systemAmber  => 'Warm Amber',
      };

  Color get seed => switch (this) {
        AppThemeChoice.systemBlue   => _seedBlue,
        AppThemeChoice.systemTeal   => _seedTeal,
        AppThemeChoice.systemPurple => _seedPurple,
        AppThemeChoice.systemAmber  => _seedAmber,
      };
}

ThemeData buildTheme(AppThemeChoice choice, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: choice.seed,
      brightness: brightness,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}