import 'package:flutter/material.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/Services/Database/transaction_service.dart';

class CancelOrderDialog extends StatelessWidget {
  final int transactionId;
  final TransactionService transactionService;
  final VoidCallback onCancelled;
  final double? orderAmount;
  final bool isPaid;

  const CancelOrderDialog({
    Key? key,
    required this.transactionId,
    required this.transactionService,
    required this.onCancelled,
    this.orderAmount,
    this.isPaid = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Cancel Order'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to cancel this order?'),
          if (isPaid) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Refund Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (orderAmount != null)
                    Text(
                      'Refund amount: Rp ${orderAmount!.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  const Text(
                    'Your refund will be processed within 3-5 business days.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No, Keep Order'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            try {
              await transactionService.cancelOrder(
                transactionId,
                CancellationReason.customer_request,
              );
              onCancelled();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel order: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context, false);
              }
            }
          },
          child: const Text('Yes, Cancel Order'),
        ),
      ],
    );
  }
}
