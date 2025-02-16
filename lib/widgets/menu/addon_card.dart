import 'package:flutter/material.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddonCard extends StatelessWidget {
  final FoodAddon addon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isEditing;

  const AddonCard({
    super.key,
    required this.addon,
    required this.onEdit,
    required this.onDelete,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addon.addonName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${addon.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.red,
                ).animate().fadeIn(duration: 200.ms).scale(),
              Switch(
                value: addon.isAvailable,
                onChanged: (value) {
                  // Implement availability toggle
                },
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}
