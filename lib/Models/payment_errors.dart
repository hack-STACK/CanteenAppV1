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
  PaymentValidationError({required super.message, super.originalError})
      : super(
          code: 'VALIDATION_ERROR',
        );
}

class StallValidationError extends PaymentError {
  StallValidationError({required super.message, super.originalError})
      : super(
          code: 'STALL_ERROR',
        );
}

class TransactionError extends PaymentError {
  TransactionError({required super.message, super.originalError})
      : super(
          code: 'TRANSACTION_ERROR',
        );
}
