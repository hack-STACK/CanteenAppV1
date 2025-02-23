import 'package:flutter/material.dart';

enum TransactionStatus {
  pending,
  confirmed,
  cooking,
  delivering,
  ready,
  completed,
  cancelled,
}

extension TransactionStatusExtension on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.confirmed:
        return 'Confirmed';
      case TransactionStatus.cooking:
        return 'Cooking';
      case TransactionStatus.delivering:
        return 'Delivering';
      case TransactionStatus.ready:
        return 'Ready';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }
}

enum PaymentStatus {
  unpaid, // Payment not made yet
  paid, // Payment successful
  refunded // Payment refunded
}

enum PaymentMethod {
  cash,
  e_wallet,
  bank_transfer,
  credit_card;

  String get label {
    return switch (this) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.e_wallet => 'E-Wallet',
      PaymentMethod.bank_transfer => 'Bank Transfer',
      PaymentMethod.credit_card => 'Credit Card',
    };
  }

  IconData get icon {
    return switch (this) {
      PaymentMethod.cash => Icons.money,
      PaymentMethod.e_wallet => Icons.account_balance_wallet,
      PaymentMethod.bank_transfer => Icons.account_balance,
      PaymentMethod.credit_card => Icons.credit_card,
    };
  }

  Color get color {
    return switch (this) {
      PaymentMethod.cash => Colors.green,
      PaymentMethod.e_wallet => Colors.blue,
      PaymentMethod.bank_transfer => Colors.purple,
      PaymentMethod.credit_card => Colors.orange,
    };
  }
}

enum OrderType {
  delivery, // Delivery order
  pickup, // Self pickup
  dine_in; // Eat at restaurant

  // Add this to ensure the value matches the database exactly
  String toJson() => name;

  // Add this for database value conversion
  String toDatabaseValue() => name;

  // Add this to parse from database value
  static OrderType fromJson(String json) {
    return OrderType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => OrderType.delivery,
    );
  }

  // Add this to parse from database value
  static OrderType fromDatabaseValue(String value) {
    return OrderType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderType.delivery,
    );
  }
}

enum CancellationReason {
  customer_request, // Customer requested cancellation
  payment_expired, // Payment timeout
  restaurant_closed, // Restaurant not available
  item_unavailable, // Menu items not available
  system_error, // Technical issues
  other // Other reasons
}

enum UserRole {
  admin_stalls, // Restaurant admin
  student // Student user
}
