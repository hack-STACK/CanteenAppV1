import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';

class MyCurrentLocation extends StatelessWidget {
  const MyCurrentLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        return Column(
          children: [
            Text('Current Address: ${restaurant.deliveryAddress}'),
            ElevatedButton(
              onPressed: () {
                restaurant.updateDeliveryAddress('New Address');
              },
              child: Text('Update Address'),
            ),
          ],
        );
      },
    );
  }
}
