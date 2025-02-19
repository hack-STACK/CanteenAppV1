import 'package:flutter/material.dart';
import 'package:kantin/Component/my_drawer_tile.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/pages/StudentState/Setting_Page.dart';
import 'package:kantin/pages/StudentState/OrderPage.dart'; // Add this import

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout(BuildContext context) async {
    final authService = AuthService();
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await authService.signOut();
        // Navigate to LoginOrRegister after logging out
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginOrRegister()),
          (route) => false, // Remove all previous routes
        );
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to logout: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Icon(
              Icons.lock_clock_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Divider(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          MyDrawerTile(
            text: "H O M E",
            icon: Icons.home,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // Navigate to home page if needed
            },
          ),
          MyDrawerTile(
            text: "S E T T I N G",
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('My Orders'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderPage()),
              );
            },
          ),
          const Spacer(),
          MyDrawerTile(
            text: "L O G O U T",
            icon: Icons.logout,
            onTap: () => logout(context),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
