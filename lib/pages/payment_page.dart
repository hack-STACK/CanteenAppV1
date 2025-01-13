import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/pages/delivery_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  GlobalKey<FormState> formKey = new GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  void userTappedPay() {
    if (formKey.currentState!.validate()) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Confirm to pay'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('Card Number = $cardNumber'),
                      Text('Expiry Date = $expiryDate'),
                      Text('Cvv Code = $cvvCode'),
                      Text('Card Holder Name = $cardHolderName'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel')),
                  TextButton(
                      onPressed: () { 
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DeliveryPage()));},
                      child: Text('Yes')),
                ],
              ));
    } else {
      print('Not Validated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Chekcout"),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              onCreditCardWidgetChange: (p0) {}),
          CreditCardForm(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              onCreditCardModelChange: (data) {
                setState(() {
                  cardNumber = data.cardNumber;
                  expiryDate = data.expiryDate;
                  cardHolderName = data.cardHolderName;
                  cvvCode = data.cvvCode;
                });
              },
              formKey: formKey),
          const Spacer(),
          MyButton(text: 'Pay now', onTap: userTappedPay),
          const SizedBox(
            height: 25,
          )
        ],
      ),
    );
  }
}
