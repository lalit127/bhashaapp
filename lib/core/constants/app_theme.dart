import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgPage,
    fontFamily: 'Nunito',
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.saffron,
      surface: AppColors.bgCard,
      error: AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontFamily: 'Nunito'),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontFamily: 'Nunito'),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Nunito'),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontFamily: 'Nunito'),
      titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Nunito'),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontFamily: 'Nunito'),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontFamily: 'Nunito'),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Nunito'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Nunito'),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      ),
    ),
  );
}
