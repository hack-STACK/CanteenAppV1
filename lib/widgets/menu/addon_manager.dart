import 'package:flutter/material.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:reorderables/reorderables.dart';

class AddonManager extends StatefulWidget {
  final List<FoodAddon> addons;
  final Function(List<FoodAddon>) onReorder;
  final Function(FoodAddon) onEdit;
  final Function(FoodAddon) onDelete;

  const AddonManager({
    super.key,
    required this.addons,
    required this.onReorder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AddonManager> createState() => _AddonManagerState();
}

class _AddonManagerState extends State<AddonManager> {
  @override
  Widget build(BuildContext context) {
    return ReorderableColumn(
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = widget.addons.removeAt(oldIndex);
          widget.addons.insert(newIndex, item);
          widget.onReorder(widget.addons);
        });
      },
      children: widget.addons.map((addon) => _buildAddonTile(addon)).toList(),
    );
  }

  Widget _buildAddonTile(FoodAddon addon) {
    return Container(
      key: ValueKey(addon.id),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(addon.addonName),
        subtitle: Text('Rp ${addon.price.toStringAsFixed(0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => widget.onEdit(addon),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => widget.onDelete(addon),
            ),
          ],
        ),
      ),
    );
  }
}
