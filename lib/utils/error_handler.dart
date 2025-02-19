import 'dart:async';

class TransactionError extends Error {
  final String message;
  final String code;
  final dynamic originalError;

  TransactionError(this.message, {this.code = 'UNKNOWN', this.originalError});

  @override
  String toString() => message;
}

class ErrorHandler {
  static TransactionError handleTransactionError(dynamic error) {
    if (error is TransactionError) return error;

    final message = error.toString().toLowerCase();

    if (message.contains('not found')) {
      return TransactionError(
        'Order not found or already cancelled',
        code: 'ORDER_NOT_FOUND',
        originalError: error,
      );
    }

    if (message.contains('permission')) {
      return TransactionError(
        'You do not have permission to cancel this order',
        code: 'PERMISSION_DENIED',
        originalError: error,
      );
    }

    if (message.contains('already cancelled')) {
      return TransactionError(
        'This order has already been cancelled',
        code: 'ALREADY_CANCELLED',
        originalError: error,
      );
    }

    if (message.contains('completed')) {
      return TransactionError(
        'Cannot cancel a completed order',
        code: 'ORDER_COMPLETED',
        originalError: error,
      );
    }

    return TransactionError(
      'Failed to cancel order: $message',
      code: 'UNKNOWN',
      originalError: error,
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return 'The operation timed out. Please try again.';
    }

    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
