import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/models/enums/transaction_enums.dart'; // Changed Models to models
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const OrderDetailsSheet({
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
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderProgress(context),
                  _buildDeliveryInfo(context),
                  _buildOrderDetails(context),
                  _buildPaymentSummary(context),
                  if (_showActionButtons(order['status']))
                    _buildActionButtons(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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
                    DateFormat('MMM d, y • h:mm a').format(
                      DateTime.parse(order['created_at']),
                    ),
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

  Widget _buildOrderDetails(BuildContext context) {
    final items = order['items'] as List?;

    if (items == null || items.isEmpty) {
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
        child: Center(
          child: Text(
            'No items found',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      );
    }

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
              Icon(Icons.receipt_long, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Order Items',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildItemRow(context, item)),
          if (order['notes']?.isNotEmpty ?? false) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.note, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['notes'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, dynamic item) {
    try {
      final quantity = item['quantity'] as int? ?? 0;
      final menuItem = item['menu'] as Map<String, dynamic>?;
      final addons =
          (item['addons'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (menuItem == null) {
        return _buildErrorCard(context, 'Menu item details not found');
      }

      final menuPrice = (menuItem['price'] as num?)?.toDouble() ?? 0;
      final menuSubtotal = menuPrice * quantity;

      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${quantity}x',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menuItem['food_name'] ?? 'Unknown Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(menuSubtotal),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (addons.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Add-ons:',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...addons
                              .map((addon) => _buildAddonItem(context, addon)),
                        ],
                      ],
                    ),
                  ),
                  // Total Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(_calculateItemTotal(menuSubtotal, addons)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (addons.isNotEmpty)
                        Text(
                          'Includes add-ons',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('Error building item row: $e\n$stack');
      return _buildErrorCard(context, 'Error displaying item');
    }
  }

  Widget _buildAddonItem(BuildContext context, Map<String, dynamic> addon) {
    try {
      final addonData = addon['addon'] as Map<String, dynamic>?;
      if (addonData == null) return const SizedBox.shrink();

      final addonQuantity = addon['quantity'] as int? ?? 0;
      final addonPrice = (addonData['price'] as num?)?.toDouble() ?? 0;
      final addonSubtotal = addonPrice * addonQuantity;

      return Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, size: 12, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${addonData['addon_name']} (${addonQuantity}x)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(addonSubtotal),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error building addon item: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Card(
      color: Colors.red[50],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateItemTotal(
      double menuSubtotal, List<Map<String, dynamic>> addons) {
    try {
      double total = menuSubtotal;
      for (var addon in addons) {
        final addonQuantity = addon['quantity'] as int? ?? 0;
        final addonPrice = (addon['addon']?['price'] as num?)?.toDouble() ?? 0;
        total += addonPrice * addonQuantity;
      }
      return total;
    } catch (e) {
      debugPrint('Error calculating total: $e');
      return menuSubtotal;
    }
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final subtotal = order['total_amount'] as num;
    const deliveryFee = 2000;
    final total = subtotal + deliveryFee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', subtotal.toDouble()),
          _buildPriceRow('Delivery Fee', deliveryFee.toDouble()),
          const Divider(height: 24),
          _buildPriceRow('Total', total.toDouble(), isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
}
