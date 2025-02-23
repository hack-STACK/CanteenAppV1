import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/orderItem.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'dart:developer' as developer;

class ModernOrderCard extends StatefulWidget {
  final Transaction order;
  final StudentModel? student;
  final Function(TransactionStatus) onStatusUpdate;
  final VoidCallback onTap;
  final List<OrderItem>? orderItems;
  final bool isLoading;

  const ModernOrderCard({
    super.key,
    required this.order,
    this.student,
    required this.onStatusUpdate,
    required this.onTap,
    this.orderItems,
    this.isLoading = false,
  });

  @override
  State<ModernOrderCard> createState() => _ModernOrderCardState();
}

class _ModernOrderCardState extends State<ModernOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _logDebug(String message) {
    // Use both print and developer.log for maximum visibility
    print('OrderCard: $message');
    developer.log(message, name: 'OrderCard');
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: OrderCard build called'); // Add this line
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme, textTheme),
                if (!widget.isLoading) ...[
                  const Divider(height: 24),
                  _buildItems(colorScheme, textTheme),
                  const Divider(height: 24),
                  _buildFooter(colorScheme, textTheme),
                ] else ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getOrderTypeIcon(),
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${widget.order.id}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(colorScheme),
                ],
              ),
              if (widget.student != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      widget.student!.studentName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(widget.order.createdAt.toLocal()),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItems(ColorScheme colorScheme, TextTheme textTheme) {
    if (widget.orderItems == null || widget.orderItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.orderItems!.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: item.menu?.photo != null
                          ? DecorationImage(
                              image: NetworkImage(item.menu!.photo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: item.menu?.photo == null
                        ? Icon(Icons.restaurant,
                            color: colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menu?.foodName ?? 'Unknown Item',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${item.quantity}x ${currencyFormatter.format(item.menu?.price ?? 0)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if ((widget.orderItems?.length ?? 0) > 2)
          Center(
            child: TextButton.icon(
              onPressed: widget.onTap,
              icon: const Icon(Icons.expand_more, size: 20),
              label: Text('${widget.orderItems!.length - 2} more items'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        _buildTotalWithSavings(colorScheme, textTheme),
        if (_canUpdateStatus(widget.order.status)) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onStatusUpdate(
                _getNextStatus(widget.order.status, widget.order.orderType),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_getActionButtonText()),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getOrderTypeIcon() {
    return switch (widget.order.orderType) {
      OrderType.delivery => Icons.delivery_dining,
      OrderType.pickup => Icons.takeout_dining,
      OrderType.dine_in => Icons.restaurant,
    };
  }

  Widget _buildStatusChip(ColorScheme colorScheme) {
    final (color, icon, label) =
        _getStatusInfo(widget.order.status, widget.order.orderType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (orderDate == today) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    }
    return DateFormat('dd MMM HH:mm').format(dateTime);
  }

  bool _canUpdateStatus(TransactionStatus status) {
    return status != TransactionStatus.completed &&
        status != TransactionStatus.cancelled;
  }

  TransactionStatus _getNextStatus(
      TransactionStatus currentStatus, OrderType orderType) {
    return switch ((currentStatus, orderType)) {
      (TransactionStatus.pending, _) => TransactionStatus.confirmed,
      (TransactionStatus.confirmed, _) => TransactionStatus.cooking,
      (TransactionStatus.cooking, OrderType.delivery) =>
        TransactionStatus.delivering,
      (TransactionStatus.cooking, _) => TransactionStatus.ready,
      (TransactionStatus.ready, _) => TransactionStatus.completed,
      (TransactionStatus.delivering, _) => TransactionStatus.completed,
      _ => currentStatus,
    };
  }

  String _getActionButtonText() {
    return switch ((widget.order.status, widget.order.orderType)) {
      (TransactionStatus.pending, _) => 'Confirm Order',
      (TransactionStatus.confirmed, _) => 'Start Cooking',
      (TransactionStatus.cooking, OrderType.delivery) => 'Send for Delivery',
      (TransactionStatus.cooking, OrderType.pickup) => 'Ready for Pickup',
      (TransactionStatus.cooking, OrderType.dine_in) => 'Ready to Serve',
      (TransactionStatus.delivering, _) => 'Mark Delivered',
      (TransactionStatus.ready, _) => 'Mark Complete',
      _ => 'Process Order',
    };
  }

  (Color, IconData, String) _getStatusInfo(
      TransactionStatus status, OrderType orderType) {
    return switch ((status, orderType)) {
      (TransactionStatus.pending, _) => (
          Colors.orange,
          Icons.schedule,
          'Pending'
        ),
      (TransactionStatus.confirmed, _) => (
          Colors.blue,
          Icons.thumb_up,
          'Confirmed'
        ),
      (TransactionStatus.cooking, _) => (
          Colors.amber,
          Icons.restaurant,
          'Cooking'
        ),
      (TransactionStatus.ready, OrderType.pickup) => (
          Colors.green,
          Icons.takeout_dining,
          'Ready for Pickup'
        ),
      (TransactionStatus.ready, OrderType.dine_in) => (
          Colors.green,
          Icons.restaurant_menu,
          'Ready to Serve'
        ),
      (TransactionStatus.ready, OrderType.delivery) => (
          Colors.green,
          Icons.delivery_dining,
          'Ready for Delivery'
        ),
      (TransactionStatus.delivering, _) => (
          Colors.purple,
          Icons.delivery_dining,
          'Delivering'
        ),
      (TransactionStatus.completed, _) => (
          Colors.green,
          Icons.check_circle,
          'Completed'
        ),
      (TransactionStatus.cancelled, _) => (
          Colors.red,
          Icons.cancel,
          'Cancelled'
        ),
    };
  }

  Widget _buildOrderItemCard(OrderItem item) {
    final itemOriginalPrice = item.menu?.originalPrice ?? 0;
    final itemCurrentPrice = item.menu?.price ?? 0;
    final itemQuantity = item.quantity ?? 1;
    final itemSubtotal = item.subtotal ?? 0;

    // Direct print statements
    print('==============================================');
    print('DEBUG: Building order item: ${item.menu?.foodName}');
    print('DEBUG: Original price: ${item.menu?.originalPrice}');
    print('DEBUG: Current price: ${item.menu?.price}');
    print('DEBUG: Quantity: ${item.quantity}');

    // Validate prices
    final itemHasDiscount =
        itemOriginalPrice > 0 && itemOriginalPrice > itemCurrentPrice;
    final discountPercentage = itemHasDiscount
        ? ((itemOriginalPrice - itemCurrentPrice) / itemOriginalPrice * 100)
            .round()
        : 0;

    // Calculate savings safely
    final itemTotalSavings = itemHasDiscount
        ? (itemOriginalPrice - itemCurrentPrice) * itemQuantity
        : 0.0;

    debugPrint('Has Discount: $itemHasDiscount');
    debugPrint('Discount Percentage: $discountPercentage%');
    debugPrint('Total Savings: $itemTotalSavings');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing image container code...
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menu?.foodName ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (itemHasDiscount && itemOriginalPrice > 0) ...[
                      Text(
                        currencyFormatter.format(itemOriginalPrice),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$discountPercentage%',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      currencyFormatter.format(itemCurrentPrice),
                      style: TextStyle(
                        color: itemHasDiscount
                            ? Colors.red[700]
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: itemHasDiscount
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormatter.format(itemSubtotal),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (itemHasDiscount && itemTotalSavings > 0)
                Text(
                  'Saved ${currencyFormatter.format(itemTotalSavings)}',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalWithSavings(ColorScheme colorScheme, TextTheme textTheme) {
    print('==============================================');
    print('DEBUG: Calculating total savings');

    double totalSavings = 0.0;

    if (widget.orderItems != null) {
      for (var item in widget.orderItems!) {
        final itemOriginalPrice = item.menu?.originalPrice ?? 0;
        final itemCurrentPrice = item.menu?.price ?? 0;
        final itemQuantity = item.quantity ?? 1;

        print('DEBUG: Item: ${item.menu?.foodName}');
        print(
            'DEBUG: Original: $itemOriginalPrice, Current: $itemCurrentPrice, Qty: $itemQuantity');

        if (itemOriginalPrice > 0 && itemOriginalPrice > itemCurrentPrice) {
          final itemSaving =
              (itemOriginalPrice - itemCurrentPrice) * itemQuantity;
          totalSavings += itemSaving;
          print('DEBUG: Item saving: $itemSaving');
        }
      }
    }

    print('DEBUG: Final total savings: $totalSavings');
    print('==============================================');

    debugPrint('Final total savings: $totalSavings');

    return Column(
      children: [
        if (totalSavings > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Savings',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currencyFormatter.format(totalSavings),
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: textTheme.titleMedium,
            ),
            Text(
              currencyFormatter.format(widget.order.totalAmount),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
