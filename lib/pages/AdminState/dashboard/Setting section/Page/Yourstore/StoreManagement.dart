// lib/screens/admin/store_management_page.dart
import 'package:flutter/material.dart';
import 'package:kantin/Models/Store_model.dart';

class StoreManagementPage extends StatefulWidget {
  const StoreManagementPage({super.key});

  @override
  State<StoreManagementPage> createState() => _StoreManagementPageState();
}

class _StoreManagementPageState extends State<StoreManagementPage> {
  Store store = Store(
    id: '1',
    name: 'My Store',
    description: 'A great store',
    ownerName: 'John Doe',
    location: 'Block A',
    imageUrl: '',
    phone: '123-456-789',
  );

  bool isPreviewMode = false;

  void updateStore(Store updatedStore) {
    setState(() {
      store = updatedStore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Management'),
        actions: [
          _buildPreviewToggle(),
        ],
      ),
      body: isPreviewMode ? _buildStorePage() : _buildEditStoreForm(),
    );
  }

  Widget _buildPreviewToggle() {
    return Switch(
      value: isPreviewMode,
      onChanged: (value) {
        setState(() {
          isPreviewMode = value;
        });
      },
    );
  }

  Widget _buildStorePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.network(
            store.imageUrl.isEmpty
                ? 'https://via.placeholder.com/400x200'
                : store.imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(store.description),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person, store.ownerName),
                _buildInfoRow(Icons.location_on, store.location),
                _buildInfoRow(Icons.phone, store.phone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditStoreForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          children: [
            TextFormField(
              initialValue: store.name,
              decoration: const InputDecoration(labelText: 'Store Name'),
              onChanged: (value) {
                // TODO: Implement form validation and saving
              },
            ),
            // Add more form fields as needed
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
