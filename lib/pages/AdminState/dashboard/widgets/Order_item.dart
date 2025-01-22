import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Assuming you're using go_router
import 'package:kantin/Models/order.dart';
import 'package:kantin/pages/AdminState/dashboard/order_detail_page.dart'; // Create this page

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
              onTap: () => _navigateToOrderDetail(context),
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

  // Navigation method
  void _navigateToOrderDetail(BuildContext context) {
    // Option 1: Using Navigator
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(order: order),
      ),
    );

    // Option 2: Using Go Router (if you're using it)
    // context.push('/order-detail', extra: order);
  }

  // ... (rest of the previous implementation remains the same)
}

// Create this page in a separate file
class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({
    Key? key, 
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onBackground,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummaryCard(colorScheme, textTheme),
              const SizedBox(height: 24),
              _buildOrderDetails(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.name,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.price,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryBadge(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Details',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          'Category',
          order.category,
          colorScheme,
          textTheme,
        ),
        // Add more detail rows as needed
      ],
    );
  }

  Widget _buildDetailRow(
    String label, 
    String value, 
    ColorScheme colorScheme, 
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.category,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}