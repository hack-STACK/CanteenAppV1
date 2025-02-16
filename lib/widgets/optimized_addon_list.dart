import 'package:flutter/material.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/widgets/addon_card.dart';

class OptimizedAddonList extends StatelessWidget {
  final List<FoodAddon> addons;
  final Function(FoodAddon) onEdit;
  final Function(FoodAddon) onDelete;

  const OptimizedAddonList({
    super.key,
    required this.addons,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addons.length,
      itemBuilder: (context, index) {
        final addon = addons[index];
        return AddonCard(
          key: ValueKey(addon.id),
          addon: addon,
          onEdit: () => onEdit(addon),
          onDelete: () => onDelete(addon),
        );
      },
    );
  }
}
