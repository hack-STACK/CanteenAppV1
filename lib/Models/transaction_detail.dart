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
  final double appliedDiscountPercentage;
  final double originalPrice;
  final double discountedPrice;

  double? _cachedTotal;
  double? _cachedSavings;

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
    this.appliedDiscountPercentage = 0.0,
    required this.originalPrice,
    required this.discountedPrice,
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
      appliedDiscountPercentage:
          (json['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['original_price'] as num).toDouble(),
      discountedPrice: (json['discounted_price'] as num).toDouble(),
    );
  }

  factory TransactionDetail.fromDetailData(Map<String, dynamic> data) {
    final originalPrice = (data['original_price'] as num).toDouble();
    final discountedPrice = (data['discounted_price'] as num).toDouble();
    final quantity = data['quantity'] as int;

    return TransactionDetail(
      id: data['id'],
      transactionId: data['transaction_id'],
      menuId: data['menu_id'],
      quantity: quantity,
      unitPrice: (data['unit_price'] as num).toDouble(),
      subtotal: discountedPrice * quantity,
      notes: data['notes'],
      createdAt: DateTime.parse(data['created_at']),
      menu: data['menu'] != null ? Menu.fromJson(data['menu']) : null,
      appliedDiscountPercentage:
          (data['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
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
      'applied_discount_percentage': appliedDiscountPercentage,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
    };
  }

  // Add helper methods for price calculations
  bool get hasDiscount => discountedPrice < originalPrice;

  double get savings {
    _cachedSavings ??= (originalPrice - discountedPrice) * quantity;
    return _cachedSavings!;
  }

  double get totalOriginalPrice => originalPrice * quantity;

  double get totalDiscountedPrice => discountedPrice * quantity;

  double get total {
    _cachedTotal ??= discountedPrice * quantity;
    return _cachedTotal!;
  }

  void clearCache() {
    _cachedTotal = null;
    _cachedSavings = null;
  }
}
