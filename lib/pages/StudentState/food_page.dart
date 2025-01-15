import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Models/Food.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:provider/provider.dart';

class FoodPage extends StatefulWidget {
  final Food food;
  final Map<foodAddOn, bool> selectedAddons = {};

  FoodPage({super.key, required this.food}) {
    for (foodAddOn addOn in food.addOns) {
      selectedAddons[addOn] = false;
    }
  }

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  void addToCart(Food food, Map<foodAddOn, bool> selectedAddOns) {
    Navigator.pop(context);
    List<foodAddOn> currentlySelectedAddons = [];
    for (foodAddOn addOn in widget.food.addOns) {
      if (widget.selectedAddons[addOn] == true) {
        currentlySelectedAddons.add(addOn);
      }
    }
    context.read<Restaurant>().addToCart(food, currentlySelectedAddons);
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive design
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Responsive image
            Image.network(
              widget.food.imagePath,
              width: screenSize.width,
              height: screenSize.height * 0.3, // Adjust height based on screen size
              fit: BoxFit.cover, // Cover the area
            ),
            Padding(
              padding: EdgeInsets.all(20), // Consistent padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.food.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Increased font size for better visibility
                    ),
                  ),
                  Text(
                    widget.food.formatPrice(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.food.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Theme.of(context).colorScheme.secondary),
                  
                  // Conditionally display the Add-ons section
                  if (widget.food.addOns.isNotEmpty) ...[
                    Text(
                      'Add-ons:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Add-ons list
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: widget.food.addOns.length,
                        itemBuilder: (BuildContext context, int index) {
                          foodAddOn addon = widget.food.addOns[index];
                          return CheckboxListTile(
                            title: Text(addon.name),
                            subtitle: Text(
                              addon.formatPrice(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            value: widget.selectedAddons[addon],
                            onChanged: (bool? value) {
                              setState(() {
                                widget.selectedAddons[addon] = value!;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Message when there are no add-ons
                    Text(
                      'No add-ons available.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            MyButton(
              text: 'Add to cart',
              onTap: () => addToCart(widget.food, widget.selectedAddons),
            ),
            const SizedBox (height: 25),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        child: Opacity(
          opacity: 0.6,
          child: Container(
            margin: EdgeInsets.only(left: 20, top: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new),
            ),
          ),
        ),
      ),
    );
  }
}