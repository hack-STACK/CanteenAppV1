import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';

class MyQuantittySelector extends StatelessWidget {
  final int quantity;
  final Menu menu;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  const MyQuantittySelector({
    super.key,
    required this.quantity,
    required this.menu,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: onRemove,
        ),
        Text('$quantity'),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: onAdd,
        ),
      ],
    );
  }
}
