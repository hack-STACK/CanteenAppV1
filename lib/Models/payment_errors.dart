class PaymentError extends Error {
  final String message;
  final String code;
  final dynamic originalError;

  PaymentError({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => 'PaymentError($code): $message';
}

class PaymentValidationError extends PaymentError {
  PaymentValidationError({required String message, dynamic originalError})
      : super(
          message: message,
          code: 'VALIDATION_ERROR',
          originalError: originalError,
        );
}

class StallValidationError extends PaymentError {
  StallValidationError({required String message, dynamic originalError})
      : super(
          message: message,
          code: 'STALL_ERROR',
          originalError: originalError,
        );
}

class TransactionError extends PaymentError {
  TransactionError({required String message, dynamic originalError})
      : super(
          message: message,
          code: 'TRANSACTION_ERROR',
          originalError: originalError,
        );
}
