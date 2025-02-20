import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/Services/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';

class OrderManagementPage extends StatefulWidget {
  final int stallId;

  const OrderManagementPage({Key? key, required this.stallId})
      : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final TransactionService _transactionService = TransactionService();
  StreamSubscription<List<Transaction>>? _orderSubscription; // Corrected type

  @override
  void initState() {
    super.initState();
    _subscribeToNewOrders();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToNewOrders() {
    _orderSubscription = _transactionService
        .subscribeToNewOrders(widget.stallId)
        .listen((transactions) {
      // Show notification for new order
      if (transactions.isNotEmpty && mounted) {
        final transaction = transactions.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New order received: #${transaction.id}'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Scroll to the new order
              },
            ),
          ),
        );
      }
    }, onError: (error) {
      // Handle errors, such as when there are no new orders
      print('Error in order subscription: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: _transactionService
            .getStallTransactions(widget.stallId), // Corrected method name
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderManagementCard(
                order: orders[index],
                onStatusUpdate: (TransactionStatus newStatus) async {
                  // Change parameter type here
                  await _transactionService.updateOrderStatus(
                    orders[index].id,
                    newStatus,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class OrderManagementCard extends StatelessWidget {
  final Transaction order;
  final Function(TransactionStatus)
      onStatusUpdate; // Change parameter type here

  const OrderManagementCard({
    Key? key,
    required this.order,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
                'Order #${order.id.toString().substring(0, 8)}'), // Convert int to String before calling substring
            subtitle: Text(order.createdAt.toString().split('.').first),
            trailing: _buildStatusChip(context),
          ),
          const Divider(),
          _buildOrderItems(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery to: ${order.deliveryAddress}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp${order.totalAmount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    switch (order.status) {
      case TransactionStatus.pending:
        chipColor = Colors.orange;
        break;
      case TransactionStatus.confirmed:
        chipColor = Colors.blue;
        break;
      case TransactionStatus.cooking:
        chipColor = Colors.amber;
        break;
      case TransactionStatus.delivering:
        chipColor = Colors.purple;
        break;
      case TransactionStatus.completed:
        chipColor = Colors.green;
        break;
      case TransactionStatus.cancelled:
        chipColor = Colors.red;
        break;
      case TransactionStatus.ready:
        chipColor = Colors.yellow;
        break;
    }

    return Chip(
      label: Text(
        order.status.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildOrderItems() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: order.details.length,
      itemBuilder: (context, index) {
        final detail = order.details[index];
        return ListTile(
          title: Text(detail.menu?.foodName ?? 'Unknown Item'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quantity: ${detail.quantity}'),
              if (detail.notes?.isNotEmpty ?? false)
                Text('Note: ${detail.notes}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.status == TransactionStatus.completed || // Update enum usage
        order.status == TransactionStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (order.status == TransactionStatus.pending) // Update enum usage
            ElevatedButton(
              onPressed: () => onStatusUpdate(
                  TransactionStatus.cooking), // Update enum usage
              child: const Text('Start Preparing'),
            ),
          if (order.status == TransactionStatus.cooking) // Update enum usage
            ElevatedButton(
              onPressed: () => onStatusUpdate(
                  TransactionStatus.delivering), // Update enum usage
              child: const Text('Mark as Ready'),
            ),
          if (order.status == TransactionStatus.delivering) // Update enum usage
            ElevatedButton(
              onPressed: () => onStatusUpdate(
                  TransactionStatus.completed), // Update enum usage
              child: const Text('Complete Order'),
            ),
          OutlinedButton(
            onPressed: () => onStatusUpdate(
                TransactionStatus.cancelled), // Update enum usage
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }
}