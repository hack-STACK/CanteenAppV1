import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/Restaurant.dart';

class PaymentSummaryCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool showDeliveryFee;

  const PaymentSummaryCard({
    super.key,
    required this.restaurant,
    this.showDeliveryFee = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final subtotal = restaurant.calculateSubtotal();
    final discount = restaurant.calculateTotalDiscount();
    final deliveryFee = showDeliveryFee ? 2000.0 : 0.0;
    final total = subtotal - discount + deliveryFee;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Subtotal', subtotal, currencyFormatter),
            if (discount > 0)
              _buildPriceRow('Discount', -discount, currencyFormatter,
                  textColor: Colors.green),
            if (showDeliveryFee)
              _buildPriceRow('Delivery Fee', deliveryFee, currencyFormatter),
            const Divider(height: 24),
            _buildPriceRow('Total', total, currencyFormatter, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    NumberFormat formatter, {
    bool isTotal = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: textColor,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
