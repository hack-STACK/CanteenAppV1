import 'package:flutter/material.dart';

class TimelineStyle {
  static const double indicatorSize = 20.0;
  static const double lineThickness = 2.0;

  static BoxDecoration indicatorDecoration(bool isActive, Color color) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isActive ? color : Colors.grey[300],
    );
  }

  static TextStyle getTextStyle(bool isActive) {
    return TextStyle(
      color: isActive ? Colors.black : Colors.grey[600],
      fontSize: 12,
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }
}
