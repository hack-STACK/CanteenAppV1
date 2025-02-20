import 'package:flutter/material.dart';

class FoodCategoryGrid extends StatelessWidget {
  final Function(String) onCategorySelected;
  final String selectedCategory;

  const FoodCategoryGrid({
    super.key,
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(category, context);
      },
    );
  }

  Widget _buildCategoryItem(CategoryItem category, BuildContext context) {
    final isSelected = selectedCategory == category.name;
    return InkWell(
      onTap: () => onCategorySelected(category.name),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              category.icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;

  const CategoryItem(this.name, this.icon);
}

final categories = [
  CategoryItem('All', Icons.restaurant),
  CategoryItem('Food', Icons.lunch_dining),
  CategoryItem('Drinks', Icons.local_drink),
  CategoryItem('Snacks', Icons.cookie),
  CategoryItem('Rice', Icons.rice_bowl),
  CategoryItem('Noodles', Icons.ramen_dining),
  CategoryItem('Dessert', Icons.icecream),
  CategoryItem('Healthy', Icons.eco),
];
