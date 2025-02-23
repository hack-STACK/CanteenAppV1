import 'package:kantin/Models/menus.dart';

class TransactionDetail {
  final int id;
  final int transactionId;
  final int menuId;
  final String? menuName;
  final double? menuPrice;
  final String? menuPhoto;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final String? addonName;
  final double? addonPrice;
  final int? addonQuantity;
  final double? addonSubtotal;
  final DateTime? createdAt;
  final double? originalPrice;
  final double? discountedPrice;
  final double? appliedDiscountPercentage;
  final Menu? menu;

  TransactionDetail({
    required this.id,
    required this.transactionId,
    required this.menuId,
    this.menuName,
    this.menuPrice,
    this.menuPhoto,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.addonName,
    this.addonPrice,
    this.addonQuantity,
    this.addonSubtotal,
    this.createdAt,
    this.originalPrice,
    this.discountedPrice,
    this.appliedDiscountPercentage,
    this.menu,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    // Handle potential numeric type mismatches
    double? parseNumericValue(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Ensure we have valid values for required fields
    final quantity = json['quantity'] ?? 1;
    final unitPrice = parseNumericValue(json['unit_price']) ??
        parseNumericValue(json['menu_price']) ??
        0.0;
    final subtotal =
        parseNumericValue(json['subtotal']) ?? (unitPrice * quantity);

    return TransactionDetail(
      id: json['id'],
      transactionId: json['transaction_id'],
      menuId: json['menu_id'],
      menuName:
          json['menu_name'] ?? json['menu']?['food_name'] ?? 'Unknown Item',
      menuPrice: parseNumericValue(json['menu_price']),
      menuPhoto: json['menu_photo'] ?? json['menu']?['photo'],
      quantity: quantity,
      unitPrice: unitPrice,
      subtotal: subtotal,
      notes: json['notes'],
      addonName: json['addon_name'],
      addonPrice: parseNumericValue(json['addon_price']),
      addonQuantity: json['addon_quantity'] ?? quantity,
      addonSubtotal: parseNumericValue(json['addon_subtotal']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      originalPrice: parseNumericValue(json['original_price']) ?? unitPrice,
      discountedPrice: parseNumericValue(json['discounted_price']) ?? unitPrice,
      appliedDiscountPercentage:
          parseNumericValue(json['applied_discount_percentage']) ?? 0.0,
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'menu_id': menuId,
      'menu_name': menuName,
      'menu_price': menuPrice,
      'menu_photo': menuPhoto,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'notes': notes,
      'addon_name': addonName,
      'addon_price': addonPrice,
      'addon_quantity': addonQuantity,
      'addon_subtotal': addonSubtotal,
      'created_at': createdAt?.toIso8601String(),
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'applied_discount_percentage': appliedDiscountPercentage,
    };
  }

  // Add helper methods for price calculations
  double get effectivePrice => discountedPrice ?? unitPrice;
  double get savings => (originalPrice ?? unitPrice) - effectivePrice;
  bool get hasDiscount => savings > 0;

  double get total {
    double baseTotal = effectivePrice * quantity;
    if (addonSubtotal != null) {
      baseTotal += addonSubtotal!;
    }
    return baseTotal;
  }

  // Add validation methods
  bool isValid() {
    return menuId > 0 &&
        quantity > 0 &&
        unitPrice >= 0 &&
        subtotal >= 0 &&
        (addonPrice == null || addonPrice! >= 0) &&
        (addonQuantity == null || addonQuantity! > 0);
  }
}
