import 'dart:math';

class Order {
  final String id;
  final String name;
  final double price;
  final String category;
  final String status;
  final DateTime orderDate;
  final String customerName;
  final int tableNumber;
  final String paymentMethod;
  final bool isPaid;

  const Order({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.status,
    required this.orderDate,
    required this.customerName,
    required this.tableNumber,
    required this.paymentMethod,
    required this.isPaid,
  });

  factory Order.dummy() {
    final random = Random();
    return Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Food Item ${random.nextInt(100)}',
      price: 25000 * (random.nextInt(5) + 1).toDouble(),
      category: ['Main Course', 'Beverage', 'Dessert'][random.nextInt(3)],
      status: ['pending', 'preparing', 'ready'][random.nextInt(3)],
      orderDate: DateTime.now(),
      customerName: 'Customer ${random.nextInt(100)}',
      tableNumber: random.nextInt(20) + 1,
      paymentMethod: ['Cash', 'QRIS'][random.nextInt(2)],
      isPaid: random.nextBool(),
    );
  }
}
