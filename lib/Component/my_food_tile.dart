import 'package:flutter/material.dart';
import 'package:kantin/Models/Food.dart';

class MyFoodTile extends StatelessWidget {
  const MyFoodTile({super.key, required this.onTap, required this.food});

  final void Function()? onTap;
  final Food food;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface, // Use onSurface color for text
                        ),
                      ),
                      Text(
                        food.formatPrice(), // Fixed the backslash issue
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .primary, // Use primary color for price
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        food.description,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(
                                  0.7), // Use onSurface with reduced opacity
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    food.imagePath,
                    height: 120,
                    width: 120, // Set width for consistency
                    fit: BoxFit.cover, // Ensure the image covers the area
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(
          color: Theme.of(context)
              .colorScheme
              .tertiary, // Use tertiary color for the divider
          endIndent: 25,
          indent: 25,
        ),
      ],
    );
  }
}
