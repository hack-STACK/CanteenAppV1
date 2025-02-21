import 'package:flutter/material.dart';

class StallMetric {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StallMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class MenuCategory {
  final String id;
  final String name;
  final IconData icon;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

enum LoadingState { initial, loading, loaded, error }
