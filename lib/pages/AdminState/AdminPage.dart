import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/pages/AdminState/Add%20Menu/addMenuItem.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';

class AdminDashboard extends StatefulWidget {
  final String canteenName;

  const AdminDashboard({super.key, required this.canteenName});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = false; // For showing loading indicator
  List<Map<String, dynamic>> _menuItems = []; // List to store menu items

  // Logout logic
  Future<void> _logout() async {
    final authService = AuthService();
    try {
      await authService.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegister()),
        (route) => false,
      );
    } catch (e) {
      _showErrorDialog('Failed to logout: $e');
    }
  }

  // Add menu to canteen
  Future<void> _addMenuToCanteen({
    required String menuName,
    required String description,
    required double price,
    required Uint8List imageData,
  }) async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('menu') // Replace 'menu' with your table name
          .insert({
        'canteen_id': widget.canteenName,
        'menu_name': menuName,
        'description': description,
        'price': price,
        'image_url': '', // Handle image upload and URL here
        'created_at': DateTime.now().toIso8601String(),
      });

      if (response.error == null) {
        // Add the new menu item to the local list
        _menuItems.add({
          'menu_name': menuName,
          'description': description,
          'price': price,
          'image_data': imageData, // Store the image data temporarily
        });
        _showSuccessSnackBar('Menu added successfully!');
      } else {
        _showErrorSnackBar('Failed to add menu: ${response.error!.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add menu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show Add Menu dialog
  void _showAddMenuDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMenuItem(
          onAddMenuItem: (menuName, description, price, imageData) {
            _addMenuToCanteen(
              menuName: menuName,
              description: description,
              price: price,
              imageData: imageData,
            );
          },
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
            ElevatedButton(
              onPressed: _showAddMenuDialog,
              child: const Text('Add Menu Item'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['menu_name']),
                      subtitle:
                          Text('${item['description']} - Rp. ${item['price']}'),
                      leading: item['image_data'] != null
                          ? Image.memory(item['image_data'],
                              width: 50, height: 50, fit: BoxFit.cover)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
