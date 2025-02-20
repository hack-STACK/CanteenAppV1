import 'package:flutter/material.dart';
import 'package:kantin/pages/StudentState/food_cart.dart';

class MySilverAppBar extends StatelessWidget {
  final Widget title;
  final Widget child;
  final List<Widget>? actions;
  final int studentId; // Add this line

  const MySilverAppBar({
    super.key,
    required this.title,
    required this.child,
    required this.studentId, // Add this line
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      centerTitle: true,
      expandedHeight: 340,
      collapsedHeight: 120,
      floating: false,
      pinned: true,
      actions: actions ??
          [
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FoodCartPage(StudentId: studentId)));
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
