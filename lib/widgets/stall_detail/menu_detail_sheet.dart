import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

class MenuDetailSheet extends StatefulWidget {
  final Menu menu;
  final List<FoodAddon> addons;
  final Function(Menu, {List<FoodAddon> addons, String? note}) onAddToCart;
  final double discountedPrice;
  final int discountPercentage;
  final bool hasSavings;
  final double savingsAmount;

  const MenuDetailSheet({
    Key? key,
    required this.menu,
    required this.addons,
    required this.onAddToCart,
    required this.discountedPrice,
    required this.discountPercentage,
    required this.hasSavings,
    required this.savingsAmount,
  }) : super(key: key);

  @override
  State<MenuDetailSheet> createState() => _MenuDetailSheetState();
}

class _MenuDetailSheetState extends State<MenuDetailSheet> {
  final TextEditingController noteController = TextEditingController();
  List<FoodAddon> selectedAddons = [];
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Image with overlay and badges
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Hero(
                          tag: 'menu_${widget.menu.id}',
                          child: Image.network(
                            widget.menu.photo ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          ),
                        ),
                      ),
                      if (widget.discountPercentage > 0)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: _buildDiscountBadge(),
                        ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Title and Availability
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.menu.foodName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (!widget.menu.isAvailable)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Out of Stock',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Price Section
                      if (widget.hasSavings) ...[
                        Row(
                          children: [
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(widget.menu.price),
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Save ${NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(widget.savingsAmount)}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                      ],
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(widget.discountedPrice),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.hasSavings
                              ? Colors.red.shade600
                              : theme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Description
                      if (widget.menu.description?.isNotEmpty == true) ...[
                        Text(
                          widget.menu.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      // Add-ons Section
                      if (widget.addons.isNotEmpty) ...[
                        Text(
                          'Add-ons',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...widget.addons.map((addon) => _buildAddonTile(addon)),
                        SizedBox(height: 24),
                      ],

                      // Quantity Section
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildQuantityButton(
                            icon: Icons.remove,
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                          ),
                          SizedBox(width: 24),
                          Text(
                            quantity.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 24),
                          _buildQuantityButton(
                            icon: Icons.add,
                            onPressed: () => setState(() => quantity++),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Special Instructions
                      Text(
                        'Special Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          hintText: 'E.g., No onions, extra spicy...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar
          Container(
            padding: EdgeInsets.all(16).copyWith(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: Offset(0, -4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format((widget.discountedPrice +
                                selectedAddons.fold(
                                    0.0, (sum, addon) => sum + addon.price)) *
                            quantity),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.hasSavings
                              ? Colors.red.shade600
                              : theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.menu.isAvailable
                        ? () {
                            widget.onAddToCart(
                              widget.menu,
                              addons: selectedAddons,
                              note: noteController.text.trim(),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.hasSavings ? Colors.red.shade600 : null,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.menu.isAvailable ? 'Add to Cart' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            '${widget.discountPercentage}% OFF',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonTile(FoodAddon addon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selectedAddons.contains(addon) ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedAddons.contains(addon)
              ? Theme.of(context).primaryColor
              : Colors.grey[300]!,
        ),
      ),
      child: CheckboxListTile(
        value: selectedAddons.contains(addon),
        onChanged: (checked) {
          setState(() {
            if (checked ?? false) {
              selectedAddons.add(addon);
            } else {
              selectedAddons.remove(addon);
            }
          });
        },
        title: Text(
          addon.addonName,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '+ ${NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(addon.price)}',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return Material(
      color:
          onPressed == null ? Colors.grey[100] : Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            icon,
            color: onPressed == null ? Colors.grey[400] : Colors.white,
          ),
        ),
      ),
    );
  }
}
