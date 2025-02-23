import 'package:kantin/models/enums/transaction_enums.dart';

extension PaymentMethodDisplay on PaymentMethod {
  String get displayLabel {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.e_wallet:
        return 'E-Wallet';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.credit_card:
        return 'Credit Card';
    }
  }

  static String getDisplayLabel(String? method) {
    if (method == null || method.isEmpty) {
      return 'Not Provided';
    }

    try {
      final paymentMethod = PaymentMethod.values.firstWhere(
        (e) => e.name.toLowerCase() == method.toLowerCase(),
      );
      return paymentMethod.displayLabel;
    } catch (_) {
      return 'Unknown Method';
    }
  }
}
