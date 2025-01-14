import 'package:flutter/material.dart';

class MyDrawerTile extends StatelessWidget {
  const MyDrawerTile({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData? icon;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25), // Responsive horizontal padding
      child: ListTile(
        title: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 16, // Consistent font size
            fontWeight: FontWeight.w500, // Slightly bolder for better readability
          ),
        ),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.inversePrimary,
          size: 24, // Adjusted icon size for better alignment
        ),
        onTap: onTap,
        // ignore: deprecated_member_use
        hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Hover effect
      ),
    );
  }
}