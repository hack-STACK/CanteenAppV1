import 'package:flutter/material.dart';

class OrderCardStyles {
  static BoxDecoration mainCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration headerDecoration(Color primaryColor) => BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
            color: primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      );

  static BoxDecoration priceBreakdownDecoration = BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(15),
    border: Border.all(color: Colors.grey.shade100),
  );

  static BoxDecoration discountBadgeDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.green.shade400, Colors.green.shade600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.green.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration quantityBadgeDecoration(Color primaryColor) =>
      BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      );

  static BoxDecoration addonSectionDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade100,
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static TextStyle headerTitleStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static TextStyle priceLabelStyle = TextStyle(
    color: Colors.grey.shade700,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle priceValueStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static TextStyle discountTextStyle = const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static TextStyle totalAmountStyle(Color primaryColor) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.5,
      );
}
