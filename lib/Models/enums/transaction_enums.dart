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
  cash, // Cash on delivery
  e_wallet, // Digital wallet payment
  bank_transfer, // Bank transfer
  credit_card // Credit card payment
}

enum OrderType {
  delivery, // Delivery order
  pickup, // Self pickup
  dine_in; // Eat at restaurant

  // Add this to ensure the value matches the database exactly
  String toJson() => name;

  // Add this to parse from database value
  static OrderType fromJson(String json) {
    return OrderType.values.firstWhere(
      (e) => e.name == json,
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


