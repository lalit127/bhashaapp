import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary       = Color(0xFF4CAF50);
  static const Color primaryDark   = Color(0xFF388E3C);
  static const Color primaryLight  = Color(0xFFE8F5E9);
  static const Color saffron       = Color(0xFFFF6B2B);
  static const Color saffronDark   = Color(0xFFD4521A);
  static const Color saffronLight  = Color(0xFFFFF3ED);
  static const Color gold          = Color(0xFFFFB800);
  static const Color goldLight     = Color(0xFFFFF8E1);
  static const Color rose          = Color(0xFFFF4081);
  static const Color roseLight     = Color(0xFFFFEBF2);
  static const Color indigo        = Color(0xFF5C6BC0);
  static const Color indigoLight   = Color(0xFFEDE7F6);
  static const Color teal          = Color(0xFF00BFA5);
  static const Color tealLight     = Color(0xFFE0F7F4);
  static const Color xpBlue        = Color(0xFF1CB0F6);
  static const Color emerald        = Color(0xFF4CAF50);
  static const Color streakColor        = Color(0xFF4CAF50);
  static const Color xpColor       = xpBlue;
  static const Color gemsPurple    = Color(0xFFCE82FF);

  // Backgrounds
  static const Color bgWhite       = Color(0xFFFFFFFF);
  static const Color bgPage        = Color(0xFFF7F7F7);
  static const Color bgCard        = Color(0xFFFFFFFF);
  static const Color bgSection     = Color(0xFFF0F0F0);
  // Legacy dark (kept for backward compat)
  static const Color bgDark        = Color(0xFF0F1923);
  static const Color bgCardLight   = Color(0xFFF0F0F0);

  // Text
  static const Color textPrimary   = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted     = Color(0xFF9E9E9E);
  static const Color textDisabled  = Color(0xFFBDBDBD);

  // UI
  static const Color border        = Color(0xFFE0E0E0);
  static const Color divider       = Color(0xFFF5F5F5);

  // Feedback
  static const Color success       = Color(0xFF4CAF50);
  static const Color successLight  = Color(0xFFE8F5E9);
  static const Color error         = Color(0xFFFF5252);
  static const Color errorLight    = Color(0xFFFFEBEE);
  static const Color errorBorder   = Color(0xFFEF9A9A);
  static const Color warning       = Color(0xFFFF9800);
  static const Color warningLight  = Color(0xFFFFF3E0);

  // Hearts / Streaks
  static const Color heart         = Color(0xFFFF4081);
  static const Color streakFire    = Color(0xFFFF6D00);

  // League
  static const Color bronze        = Color(0xFFCD7F32);
  static const Color silver        = Color(0xFF9E9E9E);
  static const Color goldLeague    = Color(0xFFFFB800);
  static const Color diamond       = Color(0xFF00BCD4);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF00BFA5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient saffronGradient = LinearGradient(
    colors: [Color(0xFFFF6B2B), Color(0xFFFF4081)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF6B2B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF00BFA5), Color(0xFF5C6BC0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFF1CB0F6), Color(0xFF5C6BC0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
}
