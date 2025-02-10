// lib/widgets/category_chip.dart
import 'package:flutter/material.dart';
import 'package:kantin/constants/colors.dart';

class CategoryChip extends StatelessWidget {
  final String category;

  const CategoryChip({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
