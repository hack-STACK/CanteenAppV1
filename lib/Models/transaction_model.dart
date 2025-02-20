import 'package:kantin/Models/orderItem.dart';
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
}

class TransactionDetail {
  final int id;
  final int menuId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;
  final Menu? menu;
  final List<OrderAddonDetail> addons;

  TransactionDetail({
    required this.id,
    required this.menuId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.menu,
    this.addons = const [],
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'],
      menuId: json['menu_id'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      notes: json['notes'],
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
      addons: (json['addons'] as List<dynamic>?)
              ?.map((addon) => OrderAddonDetail.fromJson(addon))
              .toList() ??
          [],
    );
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
