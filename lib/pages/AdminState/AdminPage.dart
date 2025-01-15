import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void logout(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();
      // Navigate to LoginOrRegister after logging out
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegister()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      // Handle logout error
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context), // Call logout function
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Total Orders'),
                subtitle: const Text('100'), // Replace with dynamic data
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Active Users'),
                subtitle: const Text('50'), // Replace with dynamic data
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Total Revenue'),
                subtitle:
                    const Text('Rp. 1,000,000'), // Replace with dynamic data
              ),
            ),
            // Add more cards or widgets as needed
          ],
        ),
      ),
    );
  }
}
