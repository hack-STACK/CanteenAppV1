import 'package:flutter/material.dart';
import 'package:kantin/models/enums/transaction_enums.dart';

class PaymentSelectionPage extends StatefulWidget {
  final double amount;
  final Function(PaymentMethod) onPaymentSelected;

  const PaymentSelectionPage({
    super.key,
    required this.amount,
    required this.onPaymentSelected,
  });

  @override
  State<PaymentSelectionPage> createState() => _PaymentSelectionPageState();
}

class _PaymentSelectionPageState extends State<PaymentSelectionPage> {
  PaymentMethod? _selectedMethod;

  final Map<PaymentMethod, Map<String, dynamic>> _paymentMethods = {
    PaymentMethod.cash: {
      'title': 'Cash Payment',
      'subtitle': 'Pay with cash on delivery',
      'icon': Icons.money,
      'color': Colors.green,
    },
    PaymentMethod.e_wallet: {
      'title': 'E-Wallet',
      'subtitle': 'Pay using digital wallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
    },
    PaymentMethod.bank_transfer: {
      'title': 'Bank Transfer',
      'subtitle': 'Pay via bank transfer',
      'icon': Icons.account_balance,
      'color': Colors.purple,
    },
    PaymentMethod.credit_card: {
      'title': 'Credit Card',
      'subtitle': 'Pay with credit/debit card',
      'icon': Icons.credit_card,
      'color': Colors.red,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Amount: Rp${widget.amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods.keys.elementAt(index);
                final details = _paymentMethods[method]!;

                return RadioListTile<PaymentMethod>(
                  value: method,
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() => _selectedMethod = value);
                  },
                  title: Text(details['title']),
                  subtitle: Text(details['subtitle']),
                  secondary: Icon(
                    details['icon'],
                    color: details['color'],
                  ),
                  selected: _selectedMethod == method,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectedMethod == null
                ? null
                : () {
                    widget.onPaymentSelected(_selectedMethod!);
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }
}
