import 'package:flutter/material.dart';
import 'package:kantin/Component/my_Cart_Tile.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/pages/StudentState/payment_page.dart';
import 'package:provider/provider.dart';

class FoodCartPage extends StatelessWidget {
  const FoodCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(builder: (context, restaurant, child) {
      final userCart = restaurant.cart;
      return Scaffold(
        appBar: AppBar(
          title: Text('Keranjang Belanja'),
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Are you sure you want to clear your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          restaurant.clearCart();
                          Navigator.pop(context);
                        },
                        child: Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.delete),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: userCart.isEmpty
                  ? Center(child: Text('Cart is empty..'))
                  : ListView.builder(
                      itemCount: userCart.length,
                      itemBuilder: (BuildContext context, int index) {
                        final cartItem = userCart[index];
                        return MyCartTile(cartItem: cartItem);
                      },
                    ),
            ),
            if (userCart.isNotEmpty) ...[
              MyButton(
                text: "Go to checkout",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentPage()),
                  );
                },
              ),
              const SizedBox(height: 25),
            ],
          ],
        ),
      );
    });
  }
}