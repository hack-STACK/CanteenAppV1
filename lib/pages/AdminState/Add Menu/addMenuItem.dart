import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/Services/feature/cropImage.dart'; // Ensure this is the correct import

class AddMenuItem extends StatefulWidget {
  final Function(String, String, double, Uint8List) onAddMenuItem;

  const AddMenuItem({super.key, required this.onAddMenuItem});

  @override
  _AddMenuItemState createState() => _AddMenuItemState();
}

class _AddMenuItemState extends State<AddMenuItem> {
  final TextEditingController menuNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  Uint8List? _croppedImage;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Navigate to the cropper with the image path
      final croppedData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropperScreen(imageAssets: [image.path]),
        ),
      );

      if (croppedData != null) {
        setState(() {
          _croppedImage = croppedData;
        });
      }
    } else {
      _showErrorDialog('No image selected.');
    }
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

  void _addMenuItem() {
    final String menuName = menuNameController.text.trim();
    final String description = descriptionController.text.trim();
    final double price = double.tryParse(priceController.text) ?? 0.0;

    if (menuName.isNotEmpty &&
        description.isNotEmpty &&
        price > 0 &&
        _croppedImage != null) {
      widget.onAddMenuItem(menuName, description, price, _croppedImage!);
      Navigator.pop(context); // Close the add menu item page
    } else {
      _showErrorDialog('Please fill in all fields and select an image.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Menu Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
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
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select and Crop Image'),
            ),
            if (_croppedImage != null)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.memory(_croppedImage!),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addMenuItem,
              child: const Text('Add Menu Item'),
            ),
          ],
        ),
      ),
    );
  }
}
