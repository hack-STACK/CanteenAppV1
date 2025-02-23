import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/models/enums/transaction_enums.dart'; // Changed Models to models
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/services/menu_service.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/utils/price_formatter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:kantin/models/enums/payment_method_extension.dart';

class OrderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;
  final MenuService _menuService = MenuService();
  Logger _logger = Logger();

  OrderDetailsSheet({
    super.key,
    required this.order,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          _buildHeader(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildOrderProgress(context)),
                SliverToBoxAdapter(child: _buildDeliveryInfo(context)),
                _buildOrderItems(context),
                SliverToBoxAdapter(child: _buildPaymentDetails(context)),
                if (_showActionButtons(order['status']))
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildActionButtons(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y • h:mm a')
                        .format(DateTime.parse(order['created_at']).toLocal()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              _buildStatusBadge(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final (Color color, IconData icon, String label) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
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

  Widget _buildOrderProgress(BuildContext context) {
    final stages = [
      (icon: Icons.receipt_long, label: 'Order Placed', done: true),
      (
        icon: Icons.thumb_up,
        label: 'Confirmed',
        done: _isStageReached('confirmed')
      ),
      (
        icon: Icons.restaurant,
        label: 'Preparing',
        done: _isStageReached('cooking')
      ),
      (
        icon: Icons.delivery_dining,
        label: 'On Delivery',
        done: _isStageReached('delivering')
      ),
      (
        icon: Icons.check_circle,
        label: 'Completed',
        done: _isStageReached('completed')
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < stages.length; i++)
            TimelineTile(
              isFirst: i == 0,
              isLast: i == stages.length - 1,
              indicatorStyle: IndicatorStyle(
                width: 24,
                height: 24,
                indicator: Container(
                  decoration: BoxDecoration(
                    color: stages[i].done
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stages[i].icon,
                    size: 16,
                    color: stages[i].done ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
              beforeLineStyle: LineStyle(
                color: stages[i].done
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              endChild: Container(
                constraints: const BoxConstraints(minHeight: 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  stages[i].label,
                  style: TextStyle(
                    color: stages[i].done
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    fontWeight:
                        stages[i].done ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context) {
    if (order['delivery_address'] == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['delivery_address'],
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStaticOrderDetails(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error loading order details: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data!['items'] as List;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildOrderItem(context, items[index]),
            childCount: items.length,
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchStaticOrderDetails() async {
    try {
      final transactionService = TransactionService();
      final result =
          await transactionService.fetchOrderTrackingDetails(order['id']);

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Failed to fetch order details');
      }

      return {
        'items': result['items'],
        'total': (result['items'] as List).fold<double>(
          0,
          (sum, item) => sum + ((item['subtotal'] as num).toDouble()),
        )
      };
    } catch (e) {
      debugPrint('Error fetching static order details: $e');
      rethrow;
    }
  }

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> item) {
    // Extract the unit price directly from the transaction details
    final unitPrice = (item['unit_price'] as num?)?.toDouble();
    final originalPrice =
        (item['original_price'] as num?)?.toDouble() ?? unitPrice ?? 0.0;
    final discountedPrice =
        (item['discounted_price'] as num?)?.toDouble() ?? originalPrice;
    final quantity = item['quantity'] as int? ?? 1;
    final discountPercentage =
        (item['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0;
    final notes = item['notes'] as String?;
    final menuItem = item['menu'] ?? {};
    final menuName = menuItem['food_name'] ?? 'Unknown Item';
    final menuPhoto = menuItem['photo'] as String?;

    // Debug print the extracted values
    print('\n=== Price Debug Info ===');
    print('Unit Price: $unitPrice');
    print('Original Price: $originalPrice');
    print('Discounted Price: $discountedPrice');
    print('Quantity: $quantity');
    print('Discount %: $discountPercentage');
    print('=====================\n');

    final hasDiscount = discountPercentage > 0;
    final savings = (originalPrice - discountedPrice) * quantity;
    final subtotal = discountedPrice * quantity;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (menuPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  menuPhoto,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (notes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: $notes',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${quantity}x',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${discountPercentage.round()}%',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    PriceFormatter.format(originalPrice * quantity),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                Text(
                  PriceFormatter.format(subtotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasDiscount ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
                if (savings > 0)
                  Text(
                    'Save ${PriceFormatter.format(savings)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(
            'Payment Method',
            _getPaymentMethod(),
            valueColor: Theme.of(context).primaryColor,
          ),
          _buildPaymentRow(
            'Payment Status',
            _getPaymentStatus(),
            valueColor: _getPaymentStatusColor(),
          ),
          const Divider(height: 24),
          _buildPaymentRow(
            'Total Amount',
            _formatPrice(order['total_amount'] ?? 0),
            valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value, {
    Color? valueColor,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethod() {
    // Extract payment method from nested transaction data if available
    final methodStr = order['transaction']?['payment_method'] ??
        order['payment_method']?.toString();

    _logger.debug('Raw payment method: $methodStr');

    if (methodStr == null) {
      _logger.warn('Payment method is null for order ${order['id']}');
      return 'Not Provided';
    }

    // Get display label from extension
    final displayLabel = PaymentMethodExtension.getDisplayLabel(methodStr);
    _logger.debug('Parsed payment method: $displayLabel');

    return displayLabel;
  }

  String _getPaymentStatus() {
    final statusStr =
        order['payment_status']?.toString().toLowerCase() ?? 'unpaid';
    try {
      final status = PaymentStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => PaymentStatus.unpaid,
      );
      switch (status) {
        case PaymentStatus.unpaid:
          return 'Unpaid';
        case PaymentStatus.paid:
          return 'Paid';
        case PaymentStatus.refunded:
          return 'Refunded';
      }
    } catch (e) {
      debugPrint('Error parsing payment status: $e');
      return 'Unpaid';
    }
  }

  Color _getPaymentStatusColor() {
    final statusStr =
        order['payment_status']?.toString().toLowerCase() ?? 'unpaid';
    try {
      final status = PaymentStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => PaymentStatus.unpaid,
      );

      return switch (status) {
        PaymentStatus.paid => Colors.green,
        PaymentStatus.unpaid => Colors.orange,
        PaymentStatus.refunded => Colors.purple,
      };
    } catch (e) {
      debugPrint('Error getting payment status color: $e');
      return Colors.grey;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order['status'].toString().toLowerCase() != 'pending') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final shouldCancel = await showDialog<CancellationReason>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Order'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Please select a reason for cancellation:'),
                    const SizedBox(height: 16),
                    ...CancellationReason.values.map(
                      (reason) => ListTile(
                        title: Text(_getCancellationReasonLabel(reason)),
                        onTap: () => Navigator.pop(context, reason),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('BACK'),
                  ),
                ],
              ),
            );

            if (shouldCancel != null) {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cancelling order...')),
              );

              final transactionService = TransactionService();
              await transactionService.cancelOrder(order['id'], shouldCancel);

              onRefresh();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error cancelling order: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Failed to cancel order'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.cancel_outlined, color: Colors.white),
        label: const Text('Cancel Order'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  String _getCancellationReasonLabel(CancellationReason reason) {
    switch (reason) {
      case CancellationReason.customer_request:
        return 'Changed my mind';
      case CancellationReason.item_unavailable:
        return 'Ordered wrong item';
      case CancellationReason.payment_expired:
        return 'Taking too long';
      case CancellationReason.restaurant_closed:
        return 'Restaurant is closed';
      case CancellationReason.other:
        return 'Other reason';
      case CancellationReason.system_error:
        return 'Technical issues';
    }
  }

  (Color, IconData, String) _getStatusInfo() {
    return switch (order['status'].toString().toLowerCase()) {
      'pending' => (Colors.orange, Icons.schedule, 'Pending'),
      'confirmed' => (Colors.blue, Icons.thumb_up, 'Confirmed'),
      'cooking' => (Colors.amber, Icons.restaurant, 'Preparing'),
      'ready' => (Colors.green, Icons.check_circle, 'Ready'),
      'delivering' => (Colors.purple, Icons.delivery_dining, 'On Delivery'),
      'completed' => (Colors.green, Icons.done_all, 'Completed'),
      'cancelled' => (Colors.red, Icons.cancel, 'Cancelled'),
      _ => (Colors.grey, Icons.help_outline, 'Unknown'),
    };
  }

  bool _isStageReached(String stage) {
    final currentStatus = order['status'].toString().toLowerCase();
    final stages = [
      'pending',
      'confirmed',
      'cooking',
      'delivering',
      'completed',
    ];

    final currentIndex = stages.indexOf(currentStatus);
    final targetIndex = stages.indexOf(stage);

    return currentIndex >= targetIndex;
  }

  bool _showActionButtons(String status) {
    return status.toLowerCase() == 'pending';
  }

  String _formatPrice(num amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Widget _buildErrorItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading item details',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 12),
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const Text('Loading item details...'),
        ],
      ),
    );
  }

  Widget _buildAddons(BuildContext context, List<Map<String, dynamic>> addons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add-ons',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...addons.map((addon) {
          final addonData = addon['addon'];
          final quantity = addon['quantity'] as int? ?? 1;
          final price = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
          final subtotal = price * quantity;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${quantity}x',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    addonData['addon_name'] ?? 'Unknown Add-on',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  _formatPrice(subtotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrderSummary() {
    double subtotal = 0;
    double totalSavings = 0;

    for (var item in order['items']) {
      final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 0.0;
      final discountedPrice =
          (item['discounted_price'] as num?)?.toDouble() ?? originalPrice;
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;

      subtotal += discountedPrice * quantity;
      totalSavings += (originalPrice - discountedPrice) * quantity;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', subtotal),
            if (totalSavings > 0) ...[
              const SizedBox(height: 8),
              _buildSavingsRow('Total Savings', totalSavings),
            ],
            const Divider(),
            _buildPriceRow('Total', subtotal, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          _formatPrice(amount),
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? Colors.green.shade700 : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatPrice(amount),
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
