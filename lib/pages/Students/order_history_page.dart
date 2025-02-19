import 'package:flutter/material.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/transaction_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Add for number formatting

class OrderHistoryPage extends StatelessWidget {
  final TransactionService _transactionService = TransactionService();

  OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = int.parse(Supabase.instance.client.auth.currentUser!.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: _transactionService.getStudentTransactions(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderHistoryCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  final Transaction order;

  const OrderHistoryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0", "id_ID");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('Order #${order.id.toString()}'),
        subtitle: Text(
          '${order.status.toString().split('.').last} - ${order.createdAt.toString().split('.').first}',
        ),
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.details.length,
            itemBuilder: (context, index) {
              final detail = order.details[index];
              return ListTile(
                title: Text(detail.menu?.foodName ?? 'Unknown Item'),
                subtitle: Text(
                  'Quantity: ${detail.quantity} x Rp${formatter.format(detail.unitPrice)}',
                ),
                trailing: Text('Rp${formatter.format(detail.subtotal)}'),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (order.deliveryAddress != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.deliveryAddress!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp${formatter.format(order.totalAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
