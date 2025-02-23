import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class PriceFormatter {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double? price) {
    if (price == null) return 'N/A';
    return _currencyFormatter.format(price);
  }

  static Map<String, dynamic> calculateTransactionPrices({
    required double originalPrice,
    double? discountedPrice,
    double? discountPercentage,
    required int quantity,
  }) {
    print('\n=== Transaction Price Calculation ===');
    print('Original Price: $originalPrice');
    print('Discounted Price: $discountedPrice');
    print('Discount %: $discountPercentage');
    print('Quantity: $quantity');

    final effectivePrice = discountedPrice ?? originalPrice;
    final subtotal = effectivePrice * quantity;
    final hasDiscount =
        discountedPrice != null && discountedPrice < originalPrice;
    final savings =
        hasDiscount ? (originalPrice - discountedPrice!) * quantity : 0.0;

    print('Effective Price: $effectivePrice');
    print('Subtotal: $subtotal');
    print('Savings: $savings');
    print('===============================\n');

    return {
      'effectivePrice': effectivePrice,
      'subtotal': subtotal,
      'savings': savings,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage ?? 0.0,
    };
  }

  static double calculateEffectivePrice({
    required double originalPrice,
    double? discountedPrice,
    double? discountPercentage,
  }) {
    if (kDebugMode) {
      print('''
=== Price Calculation Debug ===
Original Price: $originalPrice
Discounted Price: $discountedPrice
Discount Percentage: $discountPercentage%
==============================
''');
    }

    if (discountPercentage != null && discountPercentage > 0) {
      return discountedPrice ??
          (originalPrice * (1 - discountPercentage / 100));
    }
    return originalPrice;
  }

  static Map<String, dynamic> calculatePriceDetails({
    required double originalPrice,
    double? discountedPrice,
    double? discountPercentage,
    required int quantity,
  }) {
    final effectivePrice = calculateEffectivePrice(
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      discountPercentage: discountPercentage,
    );

    final subtotal = effectivePrice * quantity;
    final savings = (originalPrice - effectivePrice) * quantity;
    final hasDiscount = effectivePrice < originalPrice;
    final appliedDiscount = hasDiscount
        ? ((originalPrice - effectivePrice) / originalPrice * 100).round()
        : 0;

    return {
      'effectivePrice': effectivePrice,
      'subtotal': subtotal,
      'savings': savings,
      'hasDiscount': hasDiscount,
      'discountPercentage': appliedDiscount,
    };
  }
}
