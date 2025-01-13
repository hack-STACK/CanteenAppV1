import 'package:flutter/material.dart';
import 'package:kantin/Models/Food.dart';

class MyQuantittySelector extends StatelessWidget {
  final int quantity;
  final Food food;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const MyQuantittySelector({
    super.key,
    required this.quantity,
    required this.food,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.remove,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 20,
              child: Center(
                child: Text(quantity.toString()),
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Icon(
              Icons.add,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
