import 'package:flutter/material.dart';
import 'package:kantin/models/enums/transaction_enums.dart';

extension OrderTypeExtension on OrderType {
  String get title {
    switch (this) {
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Self Pickup';
      case OrderType.dine_in:
        return 'Dine In';
    }
  }

  String get description {
    switch (this) {
      case OrderType.delivery:
        return 'We\'ll deliver to your location';
      case OrderType.pickup:
        return 'Pick up your order at the counter';
      case OrderType.dine_in:
        return 'Eat at the canteen';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.delivery:
        return Icons.delivery_dining;
      case OrderType.pickup:
        return Icons.store_mall_directory;
      case OrderType.dine_in:
        return Icons.restaurant;
    }
  }

  Color get color {
    switch (this) {
      case OrderType.delivery:
        return Colors.blue;
      case OrderType.pickup:
        return Colors.green;
      case OrderType.dine_in:
        return Colors.orange;
    }
  }
}
