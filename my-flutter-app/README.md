### Step 1: Create the Order Page

1. **Create a new Dart file** for the Order Page, e.g., `order_page.dart`.

2. **Implement the Order Page** to fetch and display the list of orders using the `getAllOrders` method from your `TransactionService`.

```dart
import 'package:flutter/material.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/Models/transaction_model.dart'; // Adjust the import based on your model structure

class OrderPage extends StatefulWidget {
  final int studentId;

  OrderPage({required this.studentId});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = TransactionService().getAllOrders(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
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
                subtitle: Text('Total: ${order['total_amount']}'),
                onTap: () {
                  _showOrderDetailSheet(context, order['id']);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showOrderDetailSheet(BuildContext context, int orderId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => OrderDetailSheet(orderId: orderId),
    );
  }
}
```

### Step 2: Create the Order Detail Sheet

1. **Create a new Dart file** for the Order Detail Sheet, e.g., `order_detail_sheet.dart`.

2. **Implement the Order Detail Sheet** to fetch and display the details of a selected order using the `getOrderDetailsById` method from your `TransactionService`.

```dart
import 'package:flutter/material.dart';
import 'package:kantin/Services/Database/transaction_service.dart';

class OrderDetailSheet extends StatelessWidget {
  final int orderId;

  OrderDetailSheet({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
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
        final items = orderDetails['items'] as List;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ID: $orderId',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('Items:', style: TextStyle(fontSize: 18)),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['menu']['food_name']),
                      subtitle: Text('Quantity: ${item['quantity']}'),
                      trailing: Text('Subtotal: ${item['subtotal']}'),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Step 3: Integrate the Order Page into Your App

Make sure to navigate to the `OrderPage` from your main app or wherever appropriate.

```dart
import 'package:flutter/material.dart';
import 'order_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canteen App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OrderPage(studentId: 1), // Pass the student ID as needed
    );
  }
}
```

### Summary

- The `OrderPage` fetches and displays a list of orders for a student.
- Tapping on an order opens the `OrderDetailSheet`, which fetches and displays the details of that order.
- Ensure that you handle errors and loading states appropriately in your UI.

This implementation provides a basic structure. You can further enhance it with better UI/UX, error handling, and additional features as needed.