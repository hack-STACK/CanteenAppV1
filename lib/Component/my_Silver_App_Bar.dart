import 'package:flutter/material.dart';
import 'package:kantin/pages/food_cart.dart';

class MySilverAppBar extends StatelessWidget {
  const MySilverAppBar({super.key, required this.child, required this.title});
  final Widget child;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      centerTitle: true,
      expandedHeight: 340,
      collapsedHeight: 120,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FoodCartPage()));
            },
            icon: Icon(Icons.shopping_cart))
      ],
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("Canteen"),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.only(bottom: 50.0),
          child: child,
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(left: 0, right: 0, top: 0),
        expandedTitleScale: 1,
        title: title,
      ),
    );
  }
}
