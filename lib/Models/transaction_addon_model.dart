import 'package:kantin/Models/menus_addon.dart';

class TransactionAddonDetail {
  final int id;
  final int transactionDetailId;
  final int addonId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime? createdAt;
  final FoodAddon? addon; // Reference to the related food addon

  TransactionAddonDetail({
    required this.id,
    required this.transactionDetailId,
    required this.addonId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.createdAt,
    this.addon,
  }) {
    // Validate constraints from database schema
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0');
    }
    if (unitPrice < 0) {
      throw ArgumentError('Unit price must be non-negative');
    }
    if (subtotal < 0) {
      throw ArgumentError('Subtotal must be non-negative');
    }
  }

  factory TransactionAddonDetail.fromJson(Map<String, dynamic> json) {
    return TransactionAddonDetail(
      id: json['id'],
      transactionDetailId: json['transaction_detail_id'],
      addonId: json['addon_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      addon: json['addon'] != null ? FoodAddon.fromMap(json['addon']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_detail_id': transactionDetailId,
        'addon_id': addonId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'created_at': createdAt?.toIso8601String(),
        'addon': addon?.toMap(),
      };

  TransactionAddonDetail copyWith({
    int? id,
    int? transactionDetailId,
    int? addonId,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    DateTime? createdAt,
    FoodAddon? addon,
  }) {
    return TransactionAddonDetail(
      id: id ?? this.id,
      transactionDetailId: transactionDetailId ?? this.transactionDetailId,
      addonId: addonId ?? this.addonId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      addon: addon ?? this.addon,
    );
  }
}
