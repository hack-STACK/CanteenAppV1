class TransactionError implements Exception {
  final String message;
  final dynamic originalError;

  TransactionError(this.message, {this.originalError});

  @override
  String toString() =>
      'TransactionError: $message ${originalError != null ? '($originalError)' : ''}';
}
