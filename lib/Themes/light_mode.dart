import 'package:flutter/material.dart';

// Custom Colors for Light Mode
const Color primaryColor = Color(0xFFFF542D); // Orange
const Color inversePrimaryLight = Color(0xFFFF8A65); // Peach
const Color secondaryColor = Color(0xFFFED7C7); // Soft Orange
const Color backgroundColorLight = Color(0xFFFFFFFF); // White
const Color surfaceColorLight = Color(0xFFFAFAFA); // Light Grey
const Color textColorLight = Color(0xFF000000); // Black

// Light Theme
ThemeData light = ThemeData(
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: surfaceColorLight,
    background: backgroundColorLight,
    onPrimary: textColorLight,
    onSecondary: textColorLight,
    onSurface: textColorLight,
    inversePrimary: inversePrimaryLight, // Warna peach
  ),
  scaffoldBackgroundColor: backgroundColorLight,
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
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
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
  ),
);
