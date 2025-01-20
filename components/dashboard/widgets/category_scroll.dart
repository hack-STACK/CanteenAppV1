import 'package:flutter/material.dart';

class CategoryScroll extends StatelessWidget {
  const CategoryScroll({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 26),
      child: Row(
        children: [
          _buildCategoryChip(true),
          _buildCategoryChip(false),
          _buildCategoryChip(false),
          _buildCategoryChip(false),
          _buildCategoryChip(false),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFFF542D).withOpacity(0.5)
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFFCBCBCB).withOpacity(0.75)
              : const Color(0xFFFF542D).withOpacity(0.2),
        ),
      ),
      child: Text(
        'Lorem ipsum',
        style: TextStyle(
          color: isSelected ? const Color(0xFFEFEFEF) : Colors.black,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}