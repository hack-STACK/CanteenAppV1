import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/Models/menu.dart';
import 'package:kantin/Services/Database/menu_service.dart'; // Import your Menu model
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminDashboard extends StatefulWidget {
  final String canteenName;

  const AdminDashboard({super.key, required this.canteenName});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = false; // For showing loading indicator

  // Logout logic
  void logout(BuildContext context) async {
    final authService = AuthService();
    try {
      await authService.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginOrRegister()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to logout: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Add menu to canteen
 Future<void> addMenuToCanteen({
  required String canteenId,
  required String menuName,
  required String description,
  required double price,
  required String imageUrl,
}) async {
  setState(() {
    _isLoading = true; // Show loading indicator
  });

  Map<String, dynamic> menuData = {
    'menuName': menuName,
    'description': description,
    'price': price,
    'imageUrl': imageUrl, // Add image URL to menu data
    'createdAt': Timestamp.now(),
  };

  try {
    await FirebaseFirestore.instance
        .collection('Canteens')
        .doc(canteenId)
        .update({
      'menus': FieldValue.arrayUnion([menuData]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menu added successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add menu: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false; // Hide loading indicator
    });
  }
}


  // Show Add Menu dialog


void _showAddMenuDialog(BuildContext context, String canteenName) {
  final TextEditingController menuNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  File? selectedImage; // To store the selected image
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String menuName) async {
    if (selectedImage == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('canteens/$canteenName/menus/$menuName.jpg');
      final uploadTask = await storageRef.putFile(selectedImage!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return null;
    }
  }

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Add Menu Item for $canteenName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: menuNameController,
              decoration: const InputDecoration(labelText: 'Menu Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            selectedImage != null
                ? Image.file(selectedImage!, height: 100, width: 100)
                : TextButton(
                    onPressed: _pickImage,
                    child: const Text('Select Image'),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final menuName = menuNameController.text.trim();
              final description = descriptionController.text.trim();
              final double price =
                  double.tryParse(priceController.text) ?? 0.0;

              if (menuName.isNotEmpty && price > 0) {
                String? imageUrl = await _uploadImage(menuName);

                if (imageUrl != null) {
                  await addMenuToCanteen(
                    canteenId: widget.canteenName,
                    menuName: menuName,
                    description: description,
                    price: price,
                    imageUrl: imageUrl, // Pass the image URL
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to upload image.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid input.')),
                );
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
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
            // Use FutureBuilder or StreamBuilder for dynamic data (orders, users, revenue)
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
            ElevatedButton(
              onPressed: () => _showAddMenuDialog(context, widget.canteenName), // Pass canteenName
              child: const Text('Add Menu Item'),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
