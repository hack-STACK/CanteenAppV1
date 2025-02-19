class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  ApiException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class ValidationException extends ApiException {
  ValidationException(String message)
      : super(message, code: 'VALIDATION_ERROR');
}

class DatabaseException extends ApiException {
  DatabaseException(String message, {dynamic originalError})
      : super(message, code: 'DATABASE_ERROR', details: originalError);
}

class TransactionError extends ApiException {
  TransactionError(String message, {String? code}) : super(message, code: code);
}

class PaymentError extends ApiException {
  PaymentError(String message, {String? code}) : super(message, code: code);
}
