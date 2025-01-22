import 'package:flutter/material.dart';
import 'package:kantin/Models/order.dart';

class OrderItem extends StatelessWidget {
  final Order order;
  final String? notificationCount;

  const OrderItem({
    Key? key,
    required this.order,
    this.notificationCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildItemImage(colorScheme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildItemName(colorScheme),
                                const SizedBox(height: 8),
                                _buildItemPrice(colorScheme),
                                const SizedBox(height: 12),
                                _buildCategoryBadge(colorScheme),
                              ],
                            ),
                          ),
                          _buildChevronIcon(colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (notificationCount != null)
          Positioned(
            top: 8,
            right: 8,
            child: _buildNotificationBadge(colorScheme),
          ),
      ],
    );
  }

  Widget _buildItemImage(ColorScheme colorScheme) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // You can add an image here using Image.network() or Image.asset()
    );
  }

  Widget _buildItemName(ColorScheme colorScheme) {
    return Text(
      order.name,
      style: TextStyle(
        color: colorScheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Figtree',
        height: 1.2,
      ),
    );
  }

  Widget _buildItemPrice(ColorScheme colorScheme) {
    return Text(
      order.price.toString(),
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Figtree',
        height: 1.2,
      ),
    );
  }

  Widget _buildCategoryBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        order.category,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Figtree',
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildChevronIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurface,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        notificationCount!,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
