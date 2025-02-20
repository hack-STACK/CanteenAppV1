import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF2B2D42);
  static const Color secondary = Color(0xFF8D99AE);
  
  // Status colors
  static const statusColors = {
    'pending': Color(0xFFFFA726),    // Warm orange
    'confirmed': Color(0xFF42A5F5),   // Bright blue
    'cooking': Color(0xFFFF7043),     // Cooking orange
    'ready': Color(0xFF66BB6A),       // Success green
    'delivering': Color(0xFF5C6BC0),  // Royal blue
    'completed': Color(0xFF26A69A),   // Teal
    'cancelled': Color(0xFFEF5350),   // Soft red
  };

  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text colors
  static const Color textPrimary = Color(0xFF2B2D42);
  static const Color textSecondary = Color(0xFF8D99AE);
  static const Color textLight = Color(0xFFEDF2F4);

  // Border colors
  static const Color border = Color(0xFFE9ECEF);
  static const Color divider = Color(0xFFDEE2E6);
}