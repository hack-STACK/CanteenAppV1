import 'package:flutter/material.dart';
import 'package:kantin/models/enums/transaction_enums.dart';

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash Payment';
      case PaymentMethod.e_wallet:
        return 'E-Wallet';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.credit_card:
        return 'Credit Card';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.e_wallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.bank_transfer:
        return Icons.account_balance;
      case PaymentMethod.credit_card:
        return Icons.credit_card;
    }
  }

  Color get color {
    switch (this) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.e_wallet:
        return Colors.blue;
      case PaymentMethod.bank_transfer:
        return Colors.purple;
      case PaymentMethod.credit_card:
        return Colors.red;
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.cash:
        return 'Pay with cash on delivery';
      case PaymentMethod.e_wallet:
        return 'Pay using digital wallet';
      case PaymentMethod.bank_transfer:
        return 'Pay via bank transfer';
      case PaymentMethod.credit_card:
        return 'Pay with credit card';
    }
  }

  static PaymentMethod? fromString(String? value) {
    if (value == null || value.isEmpty) return null;

    try {
      return PaymentMethod.values.firstWhere(
        (method) => method.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  String get displayLabel {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash Payment';
      case PaymentMethod.e_wallet:
        return 'E-Wallet';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.credit_card:
        return 'Credit Card';
    }
  }

  static String getDisplayLabel(String? method) {
    if (method == null) {
      debugPrint('Payment method is null');
      return 'Not Provided';
    }

    if (method.isEmpty) {
      debugPrint('Payment method is empty string');
      return 'Not Provided';
    }

    try {
      final normalizedMethod = method.toLowerCase().trim();
      debugPrint('Attempting to parse payment method: $normalizedMethod');

      final paymentMethod = PaymentMethod.values.firstWhere(
        (e) => e.name.toLowerCase() == normalizedMethod,
        orElse: () {
          debugPrint('No matching payment method found for: $normalizedMethod');
          return PaymentMethod.cash; // Default to cash
        },
      );

      return paymentMethod.label;
    } catch (e) {
      debugPrint('Error parsing payment method: $method, Error: $e');
      return 'Not Provided';
    }
  }
}
