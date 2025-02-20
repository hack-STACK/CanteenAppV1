import 'package:kantin/Models/menus.dart';

class TransactionDetail {
  final int id;
  final int transactionId;
  final int menuId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final DateTime? createdAt;
  final Menu? menu;

  TransactionDetail({
    required this.id,
    required this.transactionId,
    required this.menuId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.createdAt,
    this.menu,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'],
      transactionId: json['transaction_id'],
      menuId: json['menu_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'menu_id': menuId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
