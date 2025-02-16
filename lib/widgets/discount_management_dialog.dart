import 'package:flutter/material.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menu_discount.dart';
import 'package:intl/intl.dart';
import 'package:kantin/services/database/foodService.dart';
import 'package:kantin/widgets/menu_selection_dialog.dart';

class DiscountManagementDialog extends StatelessWidget {
  final List<Discount> availableDiscounts;
  final List<MenuDiscount> appliedDiscounts;
  final int menuId;
  final Future<bool> Function(Discount) onApplyDiscount;
  final Future<bool> Function(int) onRemoveDiscount;

  const DiscountManagementDialog({
    super.key,
    required this.availableDiscounts,
    required this.appliedDiscounts,
    required this.menuId,
    required this.onApplyDiscount,
    required this.onRemoveDiscount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _buildDiscountList(context),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.discount_outlined),
          SizedBox(width: 8),
          Text(
            'Manage Discounts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountList(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: availableDiscounts.length,
        itemBuilder: (context, index) {
          final discount = availableDiscounts[index];
          final isApplied = appliedDiscounts.any(
            (d) => d.discountId == discount.id,
          );

          return ListTile(
            title: Text(discount.discountName),
            subtitle: Text(
              '${discount.discountPercentage}% off\n'
              'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - '
              '${DateFormat('MMM dd').format(discount.endDate)}',
            ),
            trailing: isApplied
                ? IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () async {
                      final menuDiscount = appliedDiscounts.firstWhere(
                        (d) => d.discountId == discount.id,
                      );
                      await onRemoveDiscount(menuDiscount.id);
                    },
                  )
                : IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => onApplyDiscount(discount),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(BuildContext context, Discount discount) {
    return Card(
      child: Column(
        children: [
          // ... existing discount info ...
          OverflowBar(
            children: [
              TextButton.icon(
                icon: Icon(Icons.restaurant_menu),
                label: Text('Select Menus'),
                onPressed: () => _showMenuSelection(context, discount),
              ),
              // ... existing buttons ...
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showMenuSelection(
      BuildContext context, Discount discount) async {
    final foodService = FoodService();
    final menus = await foodService.getAllMenuItems();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => MenuSelectionDialog(
          discount: discount,
          availableMenus: menus,
          selectedMenuIds: [], // Pass currently selected menu IDs
          onMenusSelected: (selectedIds) async {
            // Apply discount to selected menus
            for (final menuId in selectedIds) {
              await onApplyDiscount(discount);
            }
          },
        ),
      );
    }
  }
}
