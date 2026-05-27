import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w800,
        color: AppColors.grey15,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w800,
        color: AppColors.grey15,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w800,
        color: AppColors.grey15,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        color: AppColors.grey15,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        color: AppColors.grey15,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        color: AppColors.grey15,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
        color: AppColors.grey15,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        color: AppColors.grey15,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        color: AppColors.grey15,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w600,
        color: AppColors.grey15,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w800,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Montserrat',
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.surfaceMuted,
        onSecondaryContainer: AppColors.grey15,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outline: AppColors.outline,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.onSecondary,
        onError: AppColors.onError,
      ),
      textTheme: textTheme,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navigationBackground,
        selectedItemColor: AppColors.navigationSelected,
        unselectedItemColor: AppColors.navigationUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.onPrimary,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.onPrimaryMuted,
        indicatorColor: AppColors.onPrimary,
        labelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        surfaceTintColor: AppColors.surface,
        shadowColor: AppColors.grey15.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: AppColors.grey15,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.mutedText,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w800,
          color: AppColors.grey15,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(color: AppColors.mutedText),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: const TextStyle(
          color: AppColors.mutedText,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.mutedText,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primarySoft,
        selectionHandleColor: AppColors.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.outline,
          disabledForegroundColor: AppColors.mutedText,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
