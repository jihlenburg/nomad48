import 'package:flutter/material.dart';

/// LuPa-inspired color scheme for NOMAD48
/// Based on LuPa Electronics Brand Manual
class AppColors {
  // Primary
  static const primaryOrange = Color(0xFFF58025);
  static const primaryBlue = Color(0xFF1E384B);
  static const midGrey = Color(0xFF8A8A8D);
  static const lightGrey = Color(0xFFBDBBBB);

  // Secondary
  static const secondaryRed = Color(0xFFE82C2A);
  static const secondaryBlue = Color(0xFF71AEB7);
  static const secondaryGreen = Color(0xFF00B597);
  static const secondaryPurple = Color(0xFFAD889F);
}

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryOrange,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryOrange.withAlpha(30),
      onPrimaryContainer: AppColors.primaryBlue,
      secondary: AppColors.primaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.primaryBlue.withAlpha(30),
      onSecondaryContainer: AppColors.primaryBlue,
      tertiary: AppColors.secondaryBlue,
      onTertiary: Colors.white,
      error: AppColors.secondaryRed,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.primaryBlue,
      surfaceContainerHighest: const Color(0xFFF5F5F5),
      outline: AppColors.lightGrey,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: 'RedHatDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.primaryOrange,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F8F8),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryOrange,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryOrange.withAlpha(70),
      onPrimaryContainer: AppColors.primaryOrange,
      secondary: AppColors.secondaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryBlue.withAlpha(70),
      onSecondaryContainer: AppColors.secondaryBlue,
      tertiary: AppColors.secondaryGreen,
      onTertiary: Colors.white,
      error: const Color(0xFFFF6B6B), // brighter red for dark
      onError: Colors.white,
      surface: const Color(0xFF1A2F3E), // slightly lighter for cards
      onSurface: const Color(0xFFECEFF1), // high contrast text
      surfaceContainerHighest: const Color(0xFF243B4D),
      outline: const Color(0xFFAAB4BE), // brighter outline for dark
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F1D28),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontFamily: 'RedHatDisplay',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: Colors.white54,
        indicatorColor: AppColors.primaryOrange,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A2F3E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF2A4458), width: 1),
        ),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1D28),
    );
  }
}
