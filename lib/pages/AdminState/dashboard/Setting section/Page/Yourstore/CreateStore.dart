import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Services/Database/Stan_service.dart';

class CreateStoreScreen extends StatefulWidget {
  final int userId;

  const CreateStoreScreen({super.key, required this.userId});

  @override
  State<CreateStoreScreen> createState() => _CreateStoreScreenState();
}

class _CreateStoreScreenState extends State<CreateStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stanService = StanService();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedSlot = 'Slot1';

  final List<String> _slots = [
    'Slot1',
    'Slot2',
    'Slot3',
    'Slot4',
    'Slot5',
    'Slot6'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Store'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter store name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter owner name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSlot,
                      decoration: const InputDecoration(
                        labelText: 'Slot',
                        border: OutlineInputBorder(),
                      ),
                      items: _slots.map((slot) {
                        return DropdownMenuItem(
                          value: slot,
                          child: Text(slot),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSlot = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createStore,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Store'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newStan = Stan(
        id: 0, // This will be set by the database
        stanName: _nameController.text,
        ownerName: _ownerController.text,
        phone: _phoneController.text,
        slot: _selectedSlot,
        description: _descriptionController.text,
        userId: widget.userId,
      );

      await _stanService.createStan(newStan);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating store: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
