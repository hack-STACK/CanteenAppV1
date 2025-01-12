import 'package:flutter/material.dart';

// Custom Colors for Dark Mode
const Color primaryColorDark = Color(0xFFFF542D); // Bright Red-Orange
const Color secondaryColorDark = Color(0xFFB0BEC5); // Light Greyish Blue
const Color backgroundColorDark = Color(0xFF121212); // Black
const Color surfaceColorDark = Color(0xFF1E1E1E); // Dark Grey
const Color textColorDark = Color(0xFFFFFFFF); // White
const Color hintColorDark = Color(0xFFB0BEC5);

// Dark Theme
ThemeData dark = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: primaryColorDark,
    secondary: secondaryColorDark,
    surface: surfaceColorDark,
    onPrimary: textColorDark,
    onSecondary: textColorDark,
    onSurface: textColorDark,
    inversePrimary: primaryColorDark,
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
    buttonColor: primaryColorDark,
    textTheme: ButtonTextTheme.primary,
  ),
);
