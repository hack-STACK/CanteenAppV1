class TransactionError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  TransactionError(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}
