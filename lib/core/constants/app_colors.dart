import 'package:flutter/material.dart';

class AppColors {
  // Brand colors (VKU Theme: Primary Indigo / Deep Blue & Crimson)
  static const Color primary = Color(0xFF1E3A8A); // Deep Royal Blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color accent = Color(0xFF0D9488); // Teal
  static const Color secondary = Color(0xFF6366F1);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // Background & Surface
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);

  // Chart Palette (distinct vivid colors for custom canvas charts)
  static const List<Color> chartColors = [
    Color(0xFFFF6D00), // Orange
    Color(0xFF2979FF), // Blue
    Color(0xFF00BFA5), // Teal
    Color(0xFFFF5252), // Red
    Color(0xFF7C4DFF), // Purple
    Color(0xFFFFD600), // Yellow
    Color(0xFF00E676), // Green
  ];
}
