import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/Services/Database/transaction_service.dart';

class OrderDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;
  final TransactionService _transactionService = TransactionService();

  OrderDetailsSheet({
    Key? key,
    required this.order,
    required this.onRefresh,
  }) : super(key: key);

  Future<void> _showCancelOrderDialog(BuildContext context) async {
    CancellationReason? selectedReason = CancellationReason.customer_request;

    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Cancel Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to cancel this order?'),
              const SizedBox(height: 16),
              const Text('Reason for cancellation:'),
              const SizedBox(height: 8),
              DropdownButton<CancellationReason>(
                value: selectedReason,
                isExpanded: true,
                items: CancellationReason.values.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason.name.replaceAll('_', ' ').capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedReason = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Order'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );

    if (shouldCancel == true && selectedReason != null) {
      try {
        await _transactionService.cancelOrder(
          order['id'],
          selectedReason!,
        );
        onRefresh(); // Refresh the orders list
        if (context.mounted) {
          Navigator.pop(context); // Close the bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    // Only show cancel button for pending orders
    if (status.toLowerCase() == 'pending') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () => _showCancelOrderDialog(context),
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: const Text('Cancel Order'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.red,
            backgroundColor: Colors.red.withOpacity(0.1),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime orderDate = DateTime.parse(order['created_at']);

    // Convert prices to double with proper type casting
    double totalAmount = (order['total_amount'] is int)
        ? (order['total_amount'] as int).toDouble()
        : order['total_amount'] as double;

    // Fix type casting for items list
    List<Map<String, dynamic>> items = (order['items'] as List)
        .map((item) => {
              'id': item['id'] as int,
              'menu_name': item['menu_name'] as String,
              'quantity': item['quantity'] as int,
              'price': (item['price'] is int)
                  ? (item['price'] as int).toDouble()
                  : item['price'] as double,
              'subtotal': ((item['price'] is int)
                      ? (item['price'] as int).toDouble()
                      : item['price'] as double) *
                  (item['quantity'] as int),
            })
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with grab handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Order ID and QR Code
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order['id']}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('MMM d, y h:mm a').format(orderDate),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              QrImageView(
                data: 'order:${order['id']}',
                version: QrVersions.auto,
                size: 100.0,
              ),
            ],
          ),

          const Divider(height: 32),

          // Order Status
          Text(
            'Order Status',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildOrderStatus(order['status']),

          const Divider(height: 32),

          // Items
          Text(
            'Order Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Items list
                  ...items.map((item) => ListTile(
                        title: Text(item['menu_name']),
                        subtitle: Text('Quantity: ${item['quantity']}'),
                        trailing: Text(
                          'Rp ${item['subtotal'].toStringAsFixed(0)}',
                        ),
                      )),

                  const Divider(),

                  // Price Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildPriceRow('Subtotal', totalAmount),
                        _buildPriceRow('Delivery Fee', 2000),
                        const Divider(),
                        _buildPriceRow(
                          'Total',
                          totalAmount + 2000,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delivery Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Information',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  order['delivery_address'] ??
                                      'No address provided',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(context, order['status']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus(String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_getStatusMessage(status)),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.amber;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Your order is being reviewed';
      case 'confirmed':
        return 'Order confirmed and being processed';
      case 'preparing':
        return 'Your food is being prepared';
      case 'ready':
        return 'Your order is ready for pickup/delivery';
      case 'delivered':
        return 'Order completed successfully';
      case 'cancelled':
        return 'Order has been cancelled';
      default:
        return 'Status unknown';
    }
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
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
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
