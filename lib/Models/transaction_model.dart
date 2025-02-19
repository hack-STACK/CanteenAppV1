import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/Models/menus.dart'; // Add this import

class Transaction {
  final int id;
  final int studentId;
  final int stallId;
  final TransactionStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final OrderType orderType; // Add this field
  final double totalAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String? deliveryAddress;
  final DateTime? estimatedDeliveryTime;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final List<TransactionDetail> details;

  Transaction({
    required this.id,
    required this.studentId,
    required this.stallId,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.orderType, // Add this parameter
    required this.totalAmount,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.deliveryAddress,
    this.estimatedDeliveryTime,
    this.cancellationReason,
    this.cancelledAt,
    this.details = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      studentId: json['student_id'],
      stallId: json['stall_id'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['payment_method'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      orderType: OrderType.fromJson(json['order_type'] ?? 'delivery'),
      totalAmount: json['total_amount']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      notes: json['notes'],
      deliveryAddress: json['delivery_address'],
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      cancellationReason: json['cancellation_reason'],
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      details: (json['transaction_details'] as List?)
              ?.map((detail) => TransactionDetail.fromJson(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'stall_id': stallId,
        'status': status.name,
        'payment_status': paymentStatus.name,
        'payment_method': paymentMethod?.name,
        'order_type': orderType.toJson(),
        'total_amount': totalAmount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'notes': notes,
        'delivery_address': deliveryAddress,
        'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
        'cancellation_reason': cancellationReason,
        'cancelled_at': cancelledAt?.toIso8601String(),
        'transaction_details':
            details.map((detail) => detail.toJson()).toList(),
      };

  Transaction copyWith({
    int? id,
    int? studentId,
    int? stallId,
    TransactionStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    OrderType? orderType,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? deliveryAddress,
    DateTime? estimatedDeliveryTime,
    String? cancellationReason,
    DateTime? cancelledAt,
    List<TransactionDetail>? details,
  }) {
    return Transaction(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      stallId: stallId ?? this.stallId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderType: orderType ?? this.orderType,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      details: details ?? this.details,
    );
  }
}

class TransactionDetail {
  final int id;
  final int menuId;
  final Menu? menu; // Add Menu object
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes; // Change note to notes to match DB
  final List<TransactionAddon> addons;

  TransactionDetail({
    required this.id,
    required this.menuId,
    this.menu, // Add menu parameter
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
    this.addons = const [],
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'],
      menuId: json['menu_id'],
      menu: json['menu'] != null
          ? Menu.fromJson(json['menu'])
          : null, // Parse menu
      quantity: json['quantity'],
      unitPrice: json['unit_price']?.toDouble() ?? 0.0,
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      notes: json['notes'],
      addons: (json['transaction_addon_details'] as List?)
              ?.map((addon) => TransactionAddon.fromJson(addon))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'menu_id': menuId,
        'menu': menu?.toJson(), // Add menu to JSON
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'notes': notes,
        'transaction_addon_details':
            addons.map((addon) => addon.toJson()).toList(),
      };
}

class TransactionAddon {
  final int id;
  final int addonId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  TransactionAddon({
    required this.id,
    required this.addonId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory TransactionAddon.fromJson(Map<String, dynamic> json) {
    return TransactionAddon(
      id: json['id'],
      addonId: json['addon_id'],
      quantity: json['quantity'],
      unitPrice: json['unit_price']?.toDouble() ?? 0.0,
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'addon_id': addonId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}
