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
      builder: (context, restaurant, child) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Use surface color for better contrast
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16), // Consistent padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      cartItem.food.imagePath,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey[300], // Placeholder color
                          child: const Icon(Icons.error), // Error icon
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 15), // Increased spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartItem.food.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22, // Increased font size for better visibility
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          cartItem.food.formatPrice(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MyQuantittySelector(
                    quantity: cartItem.quantity,
                    food: cartItem.food,
                    onRemove: () {
                      restaurant.removeFromCart(cartItem);
                    },
                    onAdd: () {
                      restaurant.addToCart(cartItem.food, cartItem.selectedAddOns);
                    },
                  ),
                ],
              ),
            ),
            if (cartItem.selectedAddOns.isNotEmpty) // Only show if there are add-ons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: SizedBox(
                  height: 50, // Fixed height for the add-ons list
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: cartItem.selectedAddOns.map((foodAddOn) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Row(
                            children: [
                              Text(foodAddOn.name),
                              const SizedBox(width: 5),
                              Text('(${foodAddOn.formatPrice()})'),
                            ],
                          ),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onSelected: (bool selected) {
                            // Handle selection if needed
                          },
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 12,
                          ),
                          // Adding hover effect
                          showCheckmark: false,
                        ),
                      );
                    }). toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}