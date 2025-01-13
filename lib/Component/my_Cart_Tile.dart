import 'package:flutter/material.dart';
import 'package:kantin/Component/my_Quantitty_Selector.dart';
import 'package:kantin/Models/Food.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Models/cartItem.dart';
import 'package:provider/provider.dart';

class MyCartTile extends StatelessWidget {
  const MyCartTile({super.key, required this.cartItem});
  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
        builder: (context, Restaurant, child) => Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            cartItem.food.imagePath,
                            height: 100,
                            width: 100,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cartItem.food.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            Text(cartItem.food.formatPrice(),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary))
                          ],
                        ),
                        const Spacer(),
                        MyQuantittySelector(
                            quantity: cartItem.quantity,
                            food: cartItem.food,
                            onRemove: () {
                              Restaurant.removeFromCart(cartItem);
                            },
                            onAdd: () {
                              Restaurant.addToCart(
                                  cartItem.food, cartItem.selectedAddOns);
                            })
                      ],
                    ),
                  ),
                  SizedBox(
                    height: cartItem.selectedAddOns.isEmpty ? 0 : 60,
                    child: ListView(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      scrollDirection: Axis.horizontal,
                      children: cartItem.selectedAddOns
                          .map((foodAddOn) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Row(
                                    children: [
                                      // add on name
                                      Text(foodAddOn.name),
                                      // add on price
                                      Text(
                                        ' (' + foodAddOn.formatPrice() + ')',
                                      )
                                    ],
                                  ),
                                  shape: StadiumBorder(
                                      side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )),
                                  onSelected: (values) {},
                                  backgroundColor:
                                      Theme.of(context).colorScheme.secondary,
                                  labelStyle: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                      fontSize: 12),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ));
  }
}
