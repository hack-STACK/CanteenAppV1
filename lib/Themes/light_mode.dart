import 'package:flutter/material.dart';

// Custom Colors for Light Mode
const Color primaryColorLight = Color(0xFFFF542D); // Bright Red-Orange
const Color secondaryColorLight = Color(0xFFB0BEC5); // Light Greyish Blue
const Color backgroundColorLight = Color(0xFFFFFFFF); // White
const Color surfaceColorLight = Color(0xFFF5F5F5); // Light Grey
const Color textColorLight = Color(0xFF000000); // Black
const Color hintColorLight = Color(0xFFB0BEC5); // Light Grey
// Light Theme
ThemeData light = ThemeData(
  colorScheme: ColorScheme.light(
    primary: primaryColorLight,
    secondary: secondaryColorLight,
    surface: surfaceColorLight,
    onPrimary: textColorLight,
    onSecondary: textColorLight,
    onSurface: textColorLight,
    inversePrimary: primaryColorLight,
  ),
  scaffoldBackgroundColor: backgroundColorLight,
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColorLight,
    foregroundColor: textColorLight,
    elevation: 4,
    titleTextStyle: TextStyle(
      color: textColorLight,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: textColorLight, fontSize: 16),
    bodyMedium: TextStyle(color: textColorLight, fontSize: 14),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: primaryColorLight,
    textTheme: ButtonTextTheme.primary,
  ),
);
