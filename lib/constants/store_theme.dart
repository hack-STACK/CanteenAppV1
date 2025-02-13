import 'package:flutter/material.dart';

class StoreTheme {
  static const primaryColor = Color(0xFFFF3D00);
  static const secondaryColor = Color(0xFF2979FF);
  static const accentColor = Color(0xFF00C853);
  static const backgroundColor = Color(0xFFF5F5F5);
  static const textColor = Color(0xFF263238);

  static const cardShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static final menuCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [cardShadow],
  );

  static const headerTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const subheaderTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.grey,
  );

  static const priceTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );
}