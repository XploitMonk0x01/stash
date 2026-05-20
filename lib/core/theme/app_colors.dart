import 'package:flutter/material.dart';

/// Central color constants for the Stash app
class AppColors {
  AppColors._();

  // ── Dark Theme Colors ──
  static const Color darkBackground = Color(0xFF0C0C14);
  static const Color darkSurface = Color(0xFF15151E);
  static const Color darkSurfaceLight = Color(0xFF1E1E2A);
  static const Color darkBorder = Color(0xFF2A2A3A);

  // ── Light Theme Colors ──
  static const Color lightBackground = Color(0xFFF5F5FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF0F0F8);
  static const Color lightBorder = Color(0xFFE0E0EA);

  // ── Accent ──
  static const Color accent = Color(0xFF7468D4);
  static const Color accentLight = Color(0xFF9B91E4);
  static const Color accentDark = Color(0xFF5A4FBA);

  // ── Text ──
  static const Color darkTextPrimary = Color(0xFFF0F0F5);
  static const Color darkTextSecondary = Color(0xFF9090A8);
  static const Color darkTextTertiary = Color(0xFF606078);

  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6E6E82);
  static const Color lightTextTertiary = Color(0xFF9E9EB0);

  // ── Status Colors ──
  static const Color error = Color(0xFFE84855);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);

  // ── Favourite ──
  static const Color favouriteStar = Color(0xFFFFD700);

  // ── Category Colors ──
  static const Map<String, CategoryColor> categoryColors = {
    'Dev Tools': CategoryColor(
      background: Color(0xFF1A2332),
      border: Color(0xFF2A4060),
      text: Color(0xFF60A5FA),
      lightBackground: Color(0xFFDCEEFF),
      lightBorder: Color(0xFFB0D4FF),
      lightText: Color(0xFF2563EB),
    ),
    'Design': CategoryColor(
      background: Color(0xFF2D1B33),
      border: Color(0xFF5A3066),
      text: Color(0xFFC084FC),
      lightBackground: Color(0xFFF3E8FF),
      lightBorder: Color(0xFFD8B4FE),
      lightText: Color(0xFF9333EA),
    ),
    'Learning': CategoryColor(
      background: Color(0xFF1A2E1A),
      border: Color(0xFF2A5C2A),
      text: Color(0xFF4ADE80),
      lightBackground: Color(0xFFDCFCE7),
      lightBorder: Color(0xFFBBF7D0),
      lightText: Color(0xFF16A34A),
    ),
    'Finance': CategoryColor(
      background: Color(0xFF2E2A1A),
      border: Color(0xFF5C5220),
      text: Color(0xFFFBBF24),
      lightBackground: Color(0xFFFEF9C3),
      lightBorder: Color(0xFFFDE68A),
      lightText: Color(0xFFCA8A04),
    ),
    'News': CategoryColor(
      background: Color(0xFF2E1A1A),
      border: Color(0xFF5C2A2A),
      text: Color(0xFFFB7185),
      lightBackground: Color(0xFFFFE4E6),
      lightBorder: Color(0xFFFDA4AF),
      lightText: Color(0xFFE11D48),
    ),
    'Entertainment': CategoryColor(
      background: Color(0xFF1A2B2E),
      border: Color(0xFF2A555C),
      text: Color(0xFF22D3EE),
      lightBackground: Color(0xFFCFFAFE),
      lightBorder: Color(0xFF99F0FA),
      lightText: Color(0xFF0891B2),
    ),
    'Other': CategoryColor(
      background: Color(0xFF252530),
      border: Color(0xFF404055),
      text: Color(0xFFA8A8C0),
      lightBackground: Color(0xFFF0F0F5),
      lightBorder: Color(0xFFD0D0E0),
      lightText: Color(0xFF6B6B80),
    ),
  };

  /// Get category color, falling back to 'Other' for custom categories
  static CategoryColor getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['Other']!;
  }

  /// Get a color from an index for custom categories
  static CategoryColor getCustomCategoryColor(int index) {
    final colors = categoryColors.values.toList();
    return colors[index % colors.length];
  }
}

/// Holds background, border, and text colors for a category badge
class CategoryColor {
  final Color background;
  final Color border;
  final Color text;
  final Color lightBackground;
  final Color lightBorder;
  final Color lightText;

  const CategoryColor({
    required this.background,
    required this.border,
    required this.text,
    required this.lightBackground,
    required this.lightBorder,
    required this.lightText,
  });
}
