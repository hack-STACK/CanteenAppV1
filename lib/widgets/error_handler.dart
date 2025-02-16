import 'package:flutter/material.dart';

class ErrorHandler extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorHandler({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }
}
