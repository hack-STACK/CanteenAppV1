// Match exactly with database enum values
enum TransactionStatus {
  pending, // Order just placed
  confirmed, // Restaurant confirmed the order
  cooking, // Food is being prepared
  delivering, // Order is out for delivery
  completed, // Order completed successfully
  cancelled // Order was cancelled
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
