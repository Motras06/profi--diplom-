// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Основные цвета приложения
  static const Color primary = Color(0xFF009999); // Яркий теал — основной бренд
  static const Color primaryDark = Color(
    0xFF006363,
  ); // Тёмный теал для акцентов
  static const Color primaryLight = Color(
    0xFF33CCCC,
  ); // Светлый теал для выделения
  static const Color accent = Color(0xFF5CCCCC); // Мягкий акцент
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF5FFFF); // Очень лёгкий бирюзовый фон
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Color(0xFF2D3436); // Тёмно-серый для текста
  static const Color secondaryText = Color(
    0xFF636E72,
  ); // Серый для второстепенного текста
  static const Color divider = Color(0xFFE0E0E0);

  // Светлая тема
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      background: background,
      onPrimary: onPrimary,
      onSecondary: Colors.black87,
      onBackground: onBackground,
      onSurface: onBackground,
      surfaceVariant: surface,
      outline: divider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: background,
      selectedItemColor: primary,
      unselectedItemColor: secondaryText,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      labelStyle: TextStyle(color: secondaryText),
      hintStyle: TextStyle(color: secondaryText.withOpacity(0.6)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: onBackground,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onBackground,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: onBackground),
      bodyMedium: TextStyle(fontSize: 14, color: secondaryText),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onPrimary,
      ), // для кнопок
    ),
    iconTheme: const IconThemeData(color: primary),
    dividerColor: divider,
  );

  // Тёмная тема (заготовка — пока копирует светлую, но структура готова)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onPrimary: onPrimary,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryLight,
      unselectedItemColor: Colors.white70,
    ),
    // Можно дальше дорабатывать по мере необходимости
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );

  // Метод для получения темы в зависимости от системной (или можно переключать вручную)
  static ThemeData getTheme(bool isDarkMode) {
    return isDarkMode ? darkTheme : lightTheme;
  }
}
