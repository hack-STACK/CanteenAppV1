import 'package:flutter/material.dart';
import 'package:kantin/Models/Restaurant.dart';

class PaymentSummaryCard extends StatelessWidget {
  final Restaurant restaurant;

  const PaymentSummaryCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final subtotal = restaurant.calculateSubtotal();
    final deliveryFee = 2000.0; // Example delivery fee
    final total = subtotal + deliveryFee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Subtotal', subtotal),
            _buildPriceRow('Delivery Fee', deliveryFee),
            const Divider(height: 24),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
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
