### Step 1: Create the Order Page

The Order Page will display a list of orders fetched from the `transaction_details` table. You can use a `ListView` to show the orders.

```dart
import 'package:flutter/material.dart';
import 'package:kantin/Services/Database/transaction_service.dart'; // Import your TransactionService
import 'package:kantin/Models/transaction_model.dart'; // Import your Transaction model

class OrderPage extends StatefulWidget {
  final int studentId;

  OrderPage({required this.studentId});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = TransactionService().getAllOrders(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text('Order ID: ${order['id']}'),
                subtitle: Text('Total Amount: ${order['total_amount']}'),
                onTap: () {
                  // Navigate to Order Detail Sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailSheet(orderId: order['id']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

### Step 2: Create the Order Detail Sheet

The Order Detail Sheet will display the details of a selected order. You can use a `FutureBuilder` to fetch the details based on the order ID.

```dart
class OrderDetailSheet extends StatelessWidget {
  final int orderId;

  OrderDetailSheet({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: TransactionService().getOrderDetailsById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No details found.'));
          }

          final orderDetails = snapshot.data!;

          return ListView.builder(
            itemCount: orderDetails['items'].length,
            itemBuilder: (context, index) {
              final item = orderDetails['items'][index];
              return ListTile(
                title: Text(item['menu']['food_name']),
                subtitle: Text('Quantity: ${item['quantity']} - Price: ${item['subtotal']}'),
                trailing: Text('Total: ${item['subtotal']}'),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Step 3: Integrate the Order Page into Your App

Make sure to integrate the `OrderPage` into your app's navigation structure. You can call it from your main app widget or any other part of your app where you want to display the orders.

```dart
void main() {
  runApp(MaterialApp(
    home: OrderPage(studentId: 1), // Replace with actual student ID
  ));
}
```

### Step 4: Testing

Run your Flutter app and navigate to the Order Page. You should see a list of orders, and tapping on an order should take you to the Order Detail Sheet, displaying the details of that order.

### Conclusion

This implementation provides a basic structure for displaying orders and their details in your Flutter app. You can further enhance the UI and add error handling, loading indicators, and other features as needed.