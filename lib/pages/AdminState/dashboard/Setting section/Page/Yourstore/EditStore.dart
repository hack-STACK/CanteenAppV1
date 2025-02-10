// lib/widgets/admin/edit_store_form.dart
import 'package:flutter/material.dart';
import 'package:kantin/models/store.dart';

class EditStoreForm extends StatefulWidget {
  final Store store;
  final Function(Store) onUpdate;

  const EditStoreForm({
    super.key,
    required this.store,
    required this.onUpdate,
  });

  @override
  State<EditStoreForm> createState() => _EditStoreFormState();
}

class _EditStoreFormState extends State<EditStoreForm> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController locationController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.store.name);
    descController = TextEditingController(text: widget.store.description);
    locationController = TextEditingController(text: widget.store.location);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagePicker(),
          const SizedBox(height: 24),
          _buildStoreInfoForm(),
          const SizedBox(height: 24),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              image: widget.store.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.store.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.store.imageUrl == null
                ? Icon(Icons.store, size: 40, color: Colors.grey[400])
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () {
                  // TODO: Implement image picker
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Store Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: locationController,
          decoration: const InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Store Status:'),
            const SizedBox(width: 16),
            Switch(
              value: widget.store.isOpen,
              onChanged: (value) {
                final updatedStore = Store(
                  name: widget.store.name,
                  description: widget.store.description,
                  location: widget.store.location,
                  isOpen: value,
                  id: '',
                  imageUrl: '',
                );
                widget.onUpdate(updatedStore);
              },
            ),
            Text(widget.store.isOpen ? 'Open' : 'Closed'),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Menu Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to add menu item page
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // TODO: Add menu items list
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
