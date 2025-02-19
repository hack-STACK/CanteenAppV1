import 'package:flutter/material.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/Services/Database/transaction_service.dart';

class CancelOrderDialog extends StatelessWidget {
  final int transactionId;
  final TransactionService transactionService;
  final VoidCallback onCancelled;

  const CancelOrderDialog({
    Key? key,
    required this.transactionId,
    required this.transactionService,
    required this.onCancelled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order'),
      content: const Text('Are you sure you want to cancel this order?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () async {
            try {
              await transactionService.cancelOrder(
                  transactionId, CancellationReason.customer_request);
              onCancelled(); // Call callback after successful cancellation
            } catch (e) {
              // Handle error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to cancel order: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pop(context, false);
            }
          },
          child: const Text('Yes, Cancel'),
        ),
      ],
    );
  }
}
