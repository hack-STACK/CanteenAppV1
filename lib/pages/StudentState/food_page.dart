import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:provider/provider.dart';

class FoodPage extends StatefulWidget {
  final Menu menu;
  final Map<FoodAddon, bool> selectedAddons = {};

  FoodPage({super.key, required this.menu}) {
    for (FoodAddon addOn in menu.addons) {
      selectedAddons[addOn] = false;
    }
  }

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  void addToCart(Menu menu, Map<FoodAddon, bool> selectedAddOns) {
    Navigator.pop(context);
    List<FoodAddon> currentlySelectedAddons = [];
    for (FoodAddon addOn in widget.menu.addons) {
      if (widget.selectedAddons[addOn] == true) {
        currentlySelectedAddons.add(addOn);
      }
    }
    context.read<Restaurant>().addToCart(menu, addons: currentlySelectedAddons);
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
              widget.menu.photo ?? '',
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
                    widget.menu.foodName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24, // Increased font size for better visibility
                    ),
                  ),
                  Text(
                    'Rp ${widget.menu.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.menu.description ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Theme.of(context).colorScheme.secondary),
                  
                  // Conditionally display the Add-ons section
                  if (widget.menu.addons.isNotEmpty) ...[
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
                        itemCount: widget.menu.addons.length,
                        itemBuilder: (BuildContext context, int index) {
                          FoodAddon addon = widget.menu.addons[index];
                          return CheckboxListTile(
                            title: Text(addon.addonName),
                            subtitle: Text(
                              'Rp ${addon.price.toStringAsFixed(0)}',
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
              onTap: () => addToCart(widget.menu, widget.selectedAddons),
            ),
            const SizedBox(height: 25),
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