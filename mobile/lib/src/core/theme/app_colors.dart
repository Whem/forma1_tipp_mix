import 'package:flutter/material.dart';

abstract final class AppColors {
  static const f1Red = Color(0xFFE10600);
  static const f1Turquoise = Color(0xFF00D2BE);
  static const f1DarkBg = Color(0xFF0D0D0F);
  static const f1DarkCard = Color(0xFF1A1A2E);
  static const f1DarkSurface = Color(0xFF16161A);
  static const f1Gold = Color(0xFFFFD700);
  static const f1Silver = Color(0xFFC0C0C0);
  static const f1Bronze = Color(0xFFCD7F32);

  static const lightBg = Color(0xFFF5F5F8);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF0F0F4);

  static const streakFire = Color(0xFFFF6B35);
  static const jokerGold = Color(0xFFFFAA00);
  static const successGreen = Color(0xFF00C853);
  static const errorRed = Color(0xFFFF1744);

  static const teamColors = <String, Color>{
    'mclaren': Color(0xFFFF8000),
    'mercedes': Color(0xFF27F4D2),
    'red_bull': Color(0xFF3671C6),
    'ferrari': Color(0xFFE8002D),
    'williams': Color(0xFF64C4FF),
    'aston_martin': Color(0xFF229971),
    'racing_bulls': Color(0xFF6692FF),
    'haas': Color(0xFFB6BABD),
    'audi': Color(0xFF00E701),
    'alpine': Color(0xFF0093CC),
    'cadillac': Color(0xFF1F1F27),
  };
}
