import 'package:flutter/material.dart';

enum UserType { student, admin }

class AdaptiveRegistrationForm extends StatefulWidget {
  final UserType userType;

  const AdaptiveRegistrationForm({
    Key? key,
    required this.userType,
  }) : super(key: key);

  @override
  _AdaptiveRegistrationFormState createState() => _AdaptiveRegistrationFormState();
}

class _AdaptiveRegistrationFormState extends State<AdaptiveRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _canteenNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _canteenNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _formTitle {
    return widget.userType == UserType.student
        ? 'Student Registration'
        : 'Canteen Owner Registration';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 32),
          // Name field with different labels based on user type
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: widget.userType == UserType.student ? 'Full Name' : 'Owner Name',
              hintText: widget.userType == UserType.student 
                  ? 'Enter your full name'
                  : 'Enter owner name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF542D), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter the name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          
          // Conditional fields based on user type
          if (widget.userType == UserType.student) ...[
            // Address field for students
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Enter your address',
                prefixIcon: const Icon(Icons.home_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF542D), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
          ] else ...[
            // Canteen name field for admin
            TextFormField(
              controller: _canteenNameController,
              decoration: InputDecoration(
                labelText: 'Canteen Name',
                hintText: 'Enter canteen name',
                prefixIcon: const Icon(Icons.store_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF542D), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter canteen name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Description field for admin (optional)
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter canteen description',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF542D), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          // Phone number field for both types
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter phone number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF542D), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 40),
          // Submit button
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Handle form submission
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.userType == UserType.student
                        ? 'Processing Student Registration'
                        : 'Processing Canteen Registration'),
                    backgroundColor: const Color(0xFFFF542D),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF542D),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Submit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}