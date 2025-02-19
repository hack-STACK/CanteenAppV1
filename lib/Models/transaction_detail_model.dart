class TransactionDetail {
  final int id;
  final int transactionId;
  final int menuId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final DateTime createdAt;

  TransactionDetail({
    required this.id,
    required this.transactionId,
    required this.menuId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    required this.createdAt,
  });

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    return TransactionDetail(
      id: map['id'],
      transactionId: map['transaction_id'],
      menuId: map['menu_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'].toDouble(),
      subtotal: map['subtotal'].toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
