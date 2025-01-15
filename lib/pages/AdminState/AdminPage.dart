import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
                subtitle: const Text('Rp. 1,000,000'), // Replace with dynamic data
              ),
            ),
            // Add more cards or widgets as needed
          ],
        ),
      ),
    );
  }
}