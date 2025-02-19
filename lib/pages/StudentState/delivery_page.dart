import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';

class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Page'),
      ),
      body: Consumer<Restaurant>(
        builder: (context, restaurant, child) {
          return Column(
            children: [
              Text('Delivery Address: ${restaurant.deliveryAddress}'),
              ElevatedButton(
                onPressed: () {
                  final receipt = restaurant.displayReceipt();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Receipt'),
                      content: Text(receipt),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text('Show Receipt'),
              ),
              ElevatedButton(
                onPressed: () {
                  restaurant.clearCart();
                  Navigator.pop(context);
                },
                child: Text('Clear Cart'),
              ),
            ],
          );
        },
      ),
    );
  }
}
