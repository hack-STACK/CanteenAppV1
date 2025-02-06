import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onSelect;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    required this.onSelect,
  });

  static const categories = [
    {'name': 'food', 'icon': Icons.restaurant, 'label': 'Food'},
    {'name': 'drink', 'icon': Icons.local_drink, 'label': 'Drink'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = category['name'] == selectedCategory;
        return InkWell(
          onTap: () => onSelect(category['name'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF542D) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFFFF542D) : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'] as IconData,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  category['label'] as String, // Show label but store name
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
