import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/Models/menus.dart';

class Transaction {
  final int id;
  final int studentId;
  final int stallId;
  final TransactionStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final String? deliveryAddress;
  final DateTime? estimatedDeliveryTime;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final OrderType orderType;
  final List<TransactionDetail> details;

  Transaction({
    required this.id,
    required this.studentId,
    required this.stallId,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.deliveryAddress,
    this.estimatedDeliveryTime,
    this.cancellationReason,
    this.cancelledAt,
    required this.orderType,
    required this.details,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      stallId: json['stall_id'],
      studentId: json['student_id'],
      status: _parseTransactionStatus(json['status']),
      paymentStatus: _parsePaymentStatus(json['payment_status']),
      paymentMethod: _parsePaymentMethod(json['payment_method']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      notes: json['notes'],
      deliveryAddress: json['delivery_address'],
      estimatedDeliveryTime: json['estimated_delivery_time'] != null 
        ? DateTime.parse(json['estimated_delivery_time']) 
        : null,
      cancellationReason: json['cancellation_reason'],
      cancelledAt: json['cancelled_at'] != null 
        ? DateTime.parse(json['cancelled_at']) 
        : null,
      orderType: _parseOrderType(json['order_type']),
      details: (json['details'] as List<dynamic>?)
          ?.map((detail) => TransactionDetail.fromJson(detail))
          .toList() ?? [],
    );
  }

  static TransactionStatus _parseTransactionStatus(String? status) {
    if (status == null) return TransactionStatus.pending;
    return TransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => TransactionStatus.pending,
    );
  }
  

  static PaymentStatus _parsePaymentStatus(String? status) {
    if (status == null) return PaymentStatus.unpaid;
    return PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    if (method == null) return PaymentMethod.cash;
    return PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == method,
      orElse: () => PaymentMethod.cash,
    );
  }

  static OrderType _parseOrderType(String? type) {
    if (type == null) return OrderType.delivery;
    return OrderType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => OrderType.delivery,
    );
  }
}

class TransactionDetail {
  final int id;
  final int menuId;
  final Menu? menu;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final List<TransactionAddon>? addons;

  TransactionDetail({
    required this.id,
    required this.menuId,
    this.menu,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.addons,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    print('Processing transaction detail JSON: $json'); // Debug print
    
    return TransactionDetail(
      id: json['id'],
      menuId: json['menu_id'],
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'],
      addons: (json['transaction_addon_details'] as List<dynamic>?)
          ?.map((addon) => TransactionAddon.fromJson(addon))
          .toList(),
    );
  }
}

class TransactionAddon {
  final int id;
  final int transactionDetailId;
  final int addonId;
  final FoodAddon? addon;  // Add FoodAddon object
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
