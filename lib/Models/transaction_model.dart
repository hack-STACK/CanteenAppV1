import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/Models/menus.dart';

class Transaction {
  final int id;
  final int studentId;
  final String? studentName; // Added field
  final int stallId;
  final double totalAmount;
  final OrderType orderType;
  final String? deliveryAddress;
  final String? notes;
  final TransactionStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final List<TransactionDetail> details; // Changed from List<OrderItem>
  final PaymentMethod paymentMethod;

  Transaction({
    required this.id,
    required this.studentId,
    this.studentName,
    required this.stallId,
    required this.totalAmount,
    required this.orderType,
    this.deliveryAddress,
    this.notes,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.details,
    required this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student']?['name'] ?? json['student_name'],
      stallId: json['stall_id'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      orderType: OrderType.values.firstWhere(
        (e) => e.name == json['order_type'],
        orElse: () => OrderType.pickup,
      ),
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.unpaid,
      ),
      createdAt: DateTime.parse(json['created_at']),
      details: (json['details'] as List<dynamic>?)
              ?.map((detail) => TransactionDetail.fromJson(detail))
              .toList() ??
          [],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (json['payment_method'] ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'stall_id': stallId,
      'total_amount': totalAmount,
      'order_type': orderType.name,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'status': status.name,
      'payment_status': paymentStatus.name,
      'created_at': createdAt.toIso8601String(),
      'details': details.map((detail) => detail.toJson()).toList(),
      'payment_method': paymentMethod.name,
      'items': details.map((detail) => detail.toJson()).toList(),
    };
  }
}

class TransactionDetail {
  final int id;
  final int transactionId;
  final int menuId;
  final int? quantity;
  final double? unitPrice;
  final double? subtotal;
  final String? notes;
  final DateTime createdAt;
  final Menu? menu;
  final String? addonName;
  final double? addonPrice;
  final int? addonQuantity;
  final double? addonSubtotal;
  final double? originalPrice;
  final double? discountedPrice;
  final double? appliedDiscountPercentage;

  // Define addons as empty list by default
  final List<AddonDetail> addons;

  TransactionDetail({
    required this.id,
    required this.transactionId,
    required this.menuId,
    this.quantity,
    this.unitPrice,
    this.subtotal,
    this.notes,
    required this.createdAt,
    this.menu,
    this.addonName,
    this.addonPrice,
    this.addonQuantity,
    this.addonSubtotal,
    this.originalPrice,
    this.discountedPrice,
    this.appliedDiscountPercentage,
    this.addons = const [], // Initialize with empty list by default
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    // Parse any direct addon data from the transaction_details record
    List<AddonDetail> addonDetails = [];
    if (json['addon_name'] != null && json['addon_price'] != null) {
      addonDetails.add(AddonDetail(
        id: json['id'],
        addonId: null,
        addonName: json['addon_name'],
        price: json['addon_price'] != null
            ? double.parse(json['addon_price'].toString())
            : 0.0,
        quantity: json['addon_quantity'] ?? 1,
        unitPrice: json['addon_price'] != null
            ? double.parse(json['addon_price'].toString())
            : 0.0,
        subtotal: json['addon_subtotal'] != null
            ? double.parse(json['addon_subtotal'].toString())
            : 0.0,
      ));
    }

    return TransactionDetail(
      id: json['id'],
      transactionId: json['transaction_id'],
      menuId: json['menu_id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : null,
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : null,
      notes: json['notes'],
      addonName: json['addon_name'],
      addonPrice: json['addon_price'] != null
          ? double.parse(json['addon_price'].toString())
          : null,
      addonQuantity: json['addon_quantity'],
      addonSubtotal: json['addon_subtotal'] != null
          ? double.parse(json['addon_subtotal'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
      originalPrice: json['original_price'] != null
          ? double.parse(json['original_price'].toString())
          : null,
      discountedPrice: json['discounted_price'] != null
          ? double.parse(json['discounted_price'].toString())
          : null,
      appliedDiscountPercentage: json['applied_discount_percentage'] != null
          ? double.parse(json['applied_discount_percentage'].toString())
          : null,
      addons: addonDetails,
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
      'addon_name': addonName,
      'addon_price': addonPrice,
      'addon_quantity': addonQuantity,
      'addon_subtotal': addonSubtotal,
      'created_at': createdAt.toIso8601String(),
      'menu': menu?.toJson(),
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'applied_discount_percentage': appliedDiscountPercentage,
      'addons': addons.map((addon) => addon.toJson()).toList(),
    };
  }
}

// Add AddonDetail class if not already defined
class AddonDetail {
  final int id;
  final int? addonId;
  final String? addonName;
  final double? price;
  final int? quantity;
  final double? unitPrice;
  final double? subtotal;

  AddonDetail({
    required this.id,
    this.addonId,
    this.addonName,
    this.price,
    this.quantity,
    this.unitPrice,
    this.subtotal,
  });

  factory AddonDetail.fromJson(Map<String, dynamic> json) {
    return AddonDetail(
      id: json['id'],
      addonId: json['addon_id'],
      addonName: json['addon_name'] ?? json['addon']?['addon_name'],
      price: json['price'] != null
          ? double.parse(json['price'].toString())
          : json['unit_price'] != null
              ? double.parse(json['unit_price'].toString())
              : null,
      quantity: json['quantity'],
      unitPrice: json['unit_price'] != null
          ? double.parse(json['unit_price'].toString())
          : null,
      subtotal: json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'addon_id': addonId,
      'addon_name': addonName,
      'price': price,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class TransactionAddon {
  final int id;
  final int transactionDetailId;
  final int addonId;
  final FoodAddon? addon; // Add FoodAddon object
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime? createdAt;

  TransactionAddon({
    required this.id,
    required this.transactionDetailId,
    required this.addonId,
    this.addon,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.createdAt,
  });

  factory TransactionAddon.fromJson(Map<String, dynamic> json) {
    return TransactionAddon(
      id: json['id'],
      transactionDetailId: json['transaction_detail_id'],
      addonId: json['addon_id'],
      addon: json['addon'] != null ? FoodAddon.fromJson(json['addon']) : null,
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  factory TransactionAddon.fromMap(Map<String, dynamic> map) {
    return TransactionAddon(
      id: map['id'],
      transactionDetailId: map['transaction_detail_id'],
      addonId: map['addon_id'],
      addon: map['addon'] != null ? FoodAddon.fromJson(map['addon']) : null,
      quantity: map['quantity'],
      unitPrice: (map['unit_price'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_detail_id': transactionDetailId,
        'addon_id': addonId,
        'addon': addon?.toJson(),
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'created_at': createdAt?.toIso8601String(),
      };
}

// Create FoodAddon model to match your database schema
class FoodAddon {
  final int id;
  final int menuId;
  final String name;
  final double price;
  final bool isRequired;
  final int? stockQuantity;
  final bool isAvailable;
  final String? description;

  FoodAddon({
    required this.id,
    required this.menuId,
    required this.name,
    required this.price,
    required this.isRequired,
    this.stockQuantity,
    this.isAvailable = true,
    this.description,
  });

  factory FoodAddon.fromJson(Map<String, dynamic> json) {
    return FoodAddon(
      id: json['id'],
      menuId: json['menu_id'],
      name: json['addon_name'],
      price: (json['price'] as num).toDouble(),
      isRequired: json['is_required'] ?? false,
      stockQuantity: json['stock_quantity'],
      isAvailable: json['is_available'] ?? true,
      description: json['Description'], // Note: matches DB column case
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_id': menuId,
        'addon_name': name,
        'price': price,
        'is_required': isRequired,
        'stock_quantity': stockQuantity,
        'is_available': isAvailable,
        'Description': description, // Note: matches DB column case
      };
}
