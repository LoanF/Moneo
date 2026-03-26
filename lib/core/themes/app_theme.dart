import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const Radius defaultRadius = Radius.circular(16);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.mainBackground,
      primaryColor: AppColors.mainColor,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mainColor,
        secondary: AppColors.secondaryColor,
        error: AppColors.error,
        surface: AppColors.secondaryBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mainBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.mainText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: AppColors.mainText),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w900, fontSize: 32),
        headlineMedium: TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w800, fontSize: 26),
        headlineSmall: TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w700, fontSize: 22),
        titleLarge: TextStyle(color: AppColors.mainText, fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: TextStyle(color: AppColors.mainText),
        bodyMedium: TextStyle(color: AppColors.secondaryText),
        bodySmall: TextStyle(color: AppColors.secondaryText, fontSize: 12),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(double.infinity, 56)),
          backgroundColor: WidgetStatePropertyAll<Color>(AppColors.primaryRed),
          foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(defaultRadius)),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
          foregroundColor: const WidgetStatePropertyAll<Color>(AppColors.mainText),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.thirdBackground, width: 1.5)),
          shape: const WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.all(defaultRadius)),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.thirdBackground,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.grey1),
        labelStyle: TextStyle(color: AppColors.grey2),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: AppColors.mainColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(defaultRadius),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(color: AppColors.mainText, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.thirdBackground,
        contentTextStyle: const TextStyle(color: AppColors.mainText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        indicatorColor: AppColors.mainColor,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: AppColors.secondaryText);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: AppColors.secondaryText);
        }),
      ),
    );
  }
}
