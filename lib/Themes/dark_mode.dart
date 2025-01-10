import 'package:flutter/material.dart';

// Custom Colors for Dark Mode
const Color primaryColor = Color(0xFFFF542D); // Orange
const Color inversePrimaryDark = Color(0xFFD84315); // Deep Orange
const Color secondaryColor = Color(0xFFFF7043); // Orangish Red
const Color backgroundColorDark = Color(0xFF121212); // Black-ish
const Color surfaceColorDark = Color(0xFF1E1E1E); // Dark Grey
const Color textColorDark = Color(0xFFFFFFFF); // White

// Dark Theme
ThemeData dark = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: surfaceColorDark,
    background: backgroundColorDark,
    onPrimary: textColorDark,
    onSecondary: textColorDark,
    onSurface: textColorDark,
    inversePrimary: inversePrimaryDark, // Warna deep orange
  ),
  scaffoldBackgroundColor: backgroundColorDark,
  appBarTheme: AppBarTheme(
    backgroundColor: backgroundColorDark,
    foregroundColor: textColorDark,
    elevation: 4,
    titleTextStyle: TextStyle(
      color: textColorDark,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: textColorDark, fontSize: 16),
    bodyMedium: TextStyle(color: textColorDark, fontSize: 14),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
  ),
);
