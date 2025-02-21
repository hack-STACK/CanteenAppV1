import 'package:flutter/material.dart';

class FoodCategoryBar extends StatelessWidget {
  final Function(String) onCategorySelected;
  final String selectedCategory;

  const FoodCategoryBar({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  final categories = const [
    {'icon': Icons.restaurant, 'label': 'All'},
    {'icon': Icons.rice_bowl, 'label': 'Rice'},
    {'icon': Icons.local_drink, 'label': 'Drinks'},
    {'icon': Icons.cake, 'label': 'Snacks'},
    {'icon': Icons.lunch_dining, 'label': 'Noodles'},
    {'icon': Icons.icecream, 'label': 'Dessert'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category['label'] == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => onCategorySelected(category['label'] as String),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
