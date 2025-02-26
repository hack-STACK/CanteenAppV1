import 'package:flutter/material.dart';

// Define the loading state for components
enum LoadingState {
  initial,
  loading,
  loaded,
  error,
}

// Model for menu categories used in filtering
class MenuCategory {
  final String id;
  final String name;
  final IconData icon;
  final int? itemCount;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.itemCount,
  });
}

// Model for stall metrics displayed in the info section
class StallMetric {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StallMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

// Model for stall amenities
class StallAmenity {
  final String name;
  final IconData icon;
  final bool isAvailable;

  const StallAmenity({
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });

  // Convert simple string to amenity with appropriate icon
  factory StallAmenity.fromString(String name) {
    IconData icon;
    
    switch (name.toLowerCase()) {
      case 'air conditioning':
        icon = Icons.ac_unit;
        break;
      case 'seating available':
        icon = Icons.chair;
        break;
      case 'takeaway':
        icon = Icons.takeout_dining;
        break;
      case 'halal certified':
        icon = Icons.verified;
        break;
      case 'vegetarian options':
        icon = Icons.spa;
        break;
      case 'wifi':
        icon = Icons.wifi;
        break;
      default:
        icon = Icons.check_circle_outline;
    }

    return StallAmenity(
      name: name,
      icon: icon,
    );
  }
}

// Model for payment methods
class PaymentMethod {
  final String name;
  final IconData icon;
  final bool isAvailable;

  const PaymentMethod({
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });

  // Convert simple string to payment method with appropriate icon
  factory PaymentMethod.fromString(String name) {
    IconData icon;
    
    switch (name.toLowerCase()) {
      case 'cash':
        icon = Icons.payments_outlined;
        break;
      case 'qris':
        icon = Icons.qr_code;
        break;
      case 'e-wallet':
        icon = Icons.account_balance_wallet;
        break;
      case 'credit card':
        icon = Icons.credit_card;
        break;
      default:
        icon = Icons.payment;
    }

    return PaymentMethod(
      name: name,
      icon: icon,
    );
  }
}
