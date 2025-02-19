import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

enum TransactionStatus {
  pending,
  preparing,
  readyForPickup,
  delivering,
  completed,
  cancelled
}

enum PaymentStatus {
  unpaid,
  paid,
  failed,
  refunded
}

enum PaymentMethod {
  cash,
  qris,
  debit,
  credit,
  eWallet
}

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
    this.details = const [],
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      studentId: map['student_id'],
      stallId: map['stall_id'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == map['status'].toLowerCase(),
        orElse: () => TransactionStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == map['payment_status'].toLowerCase(),
        orElse: () => PaymentStatus.unpaid,
      ),
      paymentMethod: map['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last.toLowerCase() == map['payment_method'].toLowerCase(),
            )
          : null,
      totalAmount: map['total_amount'].toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      notes: map['notes'],
      deliveryAddress: map['delivery_address'],
      estimatedDeliveryTime: map['estimated_delivery_time'] != null
          ? DateTime.parse(map['estimated_delivery_time'])
          : null,
      details: (map['details'] as List?)
              ?.map((detail) => TransactionDetail.fromMap(detail))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'stall_id': stallId,
      'status': status.toString().split('.').last.toLowerCase(),
      'payment_status': paymentStatus.toString().split('.').last.toLowerCase(),
      'payment_method': paymentMethod?.toString().split('.').last.toLowerCase(),
      'total_amount': totalAmount,
      'notes': notes,
      'delivery_address': deliveryAddress,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    int? studentId,
    int? stallId,
    TransactionStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    String? deliveryAddress,
    DateTime? estimatedDeliveryTime,
    List<TransactionDetail>? details,
  }) {
    return Transaction(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      stallId: stallId ?? this.stallId,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      details: details ?? this.details,
    );
  }
}

class TransactionDetail {
  final String id;
  final String transactionId;
  final Menu menu;
  final int quantity;
  final double price;
  final List<FoodAddon> addons;
  final String? note;

  TransactionDetail({
    required this.id,
    required this.transactionId,
    required this.menu,
    required this.quantity,
    required this.price,
    required this.addons,
    this.note,
  });

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    return TransactionDetail(
      id: map['id'],
      transactionId: map['transaction_id'],
      menu: Menu.fromMap(map['menu']),
      quantity: map['quantity'],
      price: map['price'].toDouble(),
      addons: (map['addons'] as List?)
              ?.map((addon) => FoodAddon.fromMap(addon))
              .toList() ??
          [],
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'menu_id': menu.id,
      'quantity': quantity,
      'price': price,
      'note': note,
    };
  }
}