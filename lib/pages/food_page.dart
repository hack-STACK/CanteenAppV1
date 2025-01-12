import 'package:flutter/material.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/Models/Food.dart';

class FoodPage extends StatefulWidget {
  final Food food;
  final Map<foodAddOn, bool> selectedAddons = {};
  FoodPage({Key? key, required this.food}) : super(key: key) {
    for (foodAddOn addOn in food.addOns) {
      selectedAddons[addOn] = false;
    }
  }

  @override
  _FoddPageState createState() => _FoddPageState();
}

class _FoddPageState extends State<FoodPage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                Image.network(widget.food.imagePath),
                Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      Text(widget.food.formatPrice(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(widget.food.description,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(
                        height: 10,
                      ),
                      Divider(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      Text('Add-ons:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary)),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                value: widget.selectedAddons[addon],
                                onChanged: (bool? value) {
                                  setState(() {
                                    widget.selectedAddons[addon] = value!;
                                  });
                                });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                MyButton(text: 'Add to cart', onTap: () {}),
                const SizedBox(
                  height: 25,
                )
              ],
            ),
          ),
        ),
        SafeArea(
            child: Opacity(
          opacity: 0.6,
          child: Container(
            margin: EdgeInsets.only(left: 20, top: 10),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle),
            child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new)),
          ),
        ))
      ],
    );
  }
}
