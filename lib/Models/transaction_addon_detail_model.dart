class TransactionAddonDetail {
  final int id;
  final int transactionDetailId;
  final int addonId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime createdAt;

  TransactionAddonDetail({
    required this.id,
    required this.transactionDetailId,
    required this.addonId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.createdAt,
  });

  factory TransactionAddonDetail.fromMap(Map<String, dynamic> map) {
    return TransactionAddonDetail(
      id: map['id'],
      transactionDetailId: map['transaction_detail_id'],
      addonId: map['addon_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'].toDouble(),
      subtotal: map['subtotal'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
