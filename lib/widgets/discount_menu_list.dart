import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';

class DiscountMenuList extends StatelessWidget {
  final List<Menu> menus;
  final double discountPercentage;

  const DiscountMenuList({
    super.key,
    required this.menus,
    required this.discountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Affected Menus:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: menus.map((menu) {
            final discountedPrice = menu.price * (1 - discountPercentage / 100);
            return Chip(
              label: Text(
                menu.foodName,
                style: TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.grey[100],
              deleteIcon: Icon(Icons.arrow_drop_down, size: 16),
              onDeleted: () {
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(0, 0, 0, 0),
                  items: [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'Original: Rp ${menu.price.toStringAsFixed(0)}\n'
                        'Discounted: Rp ${discountedPrice.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
