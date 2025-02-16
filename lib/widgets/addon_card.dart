import 'package:flutter/material.dart';
import 'package:kantin/Models/menus_addon.dart';

class AddonCard extends StatelessWidget {
  final FoodAddon addon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddonCard({
    super.key,
    required this.addon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: addon.isRequired
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minHeight: 100),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and required badge row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              addon.addonName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (addon.isRequired) _buildRequiredBadge(context),
                        ],
                      ),
                      if (addon.description?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          addon.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(60, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(60, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price tag
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildPriceTag(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Required',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriceTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Rp ${addon.price.toStringAsFixed(0)}',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
