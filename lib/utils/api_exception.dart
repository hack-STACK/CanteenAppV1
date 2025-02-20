class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  ApiException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class ValidationException extends ApiException {
  ValidationException(super.message) : super(code: 'VALIDATION_ERROR');
}

class DatabaseException extends ApiException {
  DatabaseException(super.message, {dynamic originalError})
      : super(code: 'DATABASE_ERROR', details: originalError);
}

class TransactionError extends ApiException {
  TransactionError(super.message, {super.code});
}

class PaymentError extends ApiException {
  PaymentError(super.message, {super.code});
}
