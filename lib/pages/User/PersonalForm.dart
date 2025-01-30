import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin/Component/My_header,dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/UsersModels.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/RoleProvider.dart';
import 'package:kantin/Services/Auth/role_provider.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PersonalInfoScreen extends StatelessWidget {
  final String role;
  final String firebaseUid;
  const PersonalInfoScreen(
      {Key? key, required this.role, required this.firebaseUid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  const HeaderSection(),
                  const SizedBox(height: 32),
                  AdaptiveRegistrationForm(
                    userType: role,
                    firebaseUid: firebaseUid,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdaptiveRegistrationForm extends StatefulWidget {
  final String userType;
  final String firebaseUid;
  const AdaptiveRegistrationForm({
    Key? key,
    required this.userType,
    required this.firebaseUid,
  }) : super(key: key);

  @override
  _AdaptiveRegistrationFormState createState() =>
      _AdaptiveRegistrationFormState();
}

class _AdaptiveRegistrationFormState extends State<AdaptiveRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _canteenNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;
  final _stanService = StanService();
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _canteenNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('${widget.userType}_name') ?? '';
      _phoneController.text = prefs.getString('${widget.userType}_phone') ?? '';

      if (widget.userType == 'student') {
        _addressController.text = prefs.getString('student_address') ?? '';
      } else {
        _canteenNameController.text =
            prefs.getString('admin_canteen_name') ?? '';
        _descriptionController.text =
            prefs.getString('admin_description') ?? '';
      }
    });
  }

Future<void> _saveAndSubmit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // First save data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${widget.userType}_name', _nameController.text);
      await prefs.setString('${widget.userType}_phone', _phoneController.text);

      if (widget.userType == 'student') {
        await prefs.setString('student_address', _addressController.text);
      } else {
        await prefs.setString('admin_canteen_name', _canteenNameController.text);
        await prefs.setString('admin_description', _descriptionController.text);
      }

      // Initialize services
      final userService = UserService();
      final studentService = StudentService();

      // Check if username exists
      final usernameExists = await userService.checkUsernameExists(_nameController.text.trim());
      if (usernameExists) {
        throw Exception('Username already exists. Please choose another one.');
      }

      // Ensure you have the correct Firebase UID
      final firebaseUid = widget.firebaseUid;

      // Check if the user with the same firebase_uid already exists
      final firebaseUidExists = await userService.checkFirebaseUidExists(firebaseUid);
      if (firebaseUidExists) {
        throw Exception('User with this Firebase UID already exists.');
      }

      // Create user in users table
      final userData = UserModel(
        username: _nameController.text.trim(),
        password: '', // Handle password securely
        role: widget.userType,
        firebaseUid: firebaseUid,
        id: 0,
      );

      final createdUser = await userService.createUser(userData);
      
      if (createdUser.id == null) {
        throw Exception('Failed to create user account');
      }

      // Handle role-specific logic
      if (widget.userType == 'student') {
        // Check if student with same name exists for this user
        final studentExists = await studentService.checkStudentExists(
          _nameController.text.trim(),
          createdUser.id!
        );

        if (studentExists) {
          throw Exception('Student with this name already exists for this user.');
        }

        // Create student using StudentModels
        final studentData = StudentModels(
          studentName: _nameController.text.trim(),
          studentAddress: _addressController.text.trim(),
          studentPhoneNumber: _phoneController.text.trim(),
          userId: createdUser.id!,
          studentImage: '', // Handle image upload separately if needed
        );

        // Use StudentService to create student
        final createdStudent = await studentService.createStudent(studentData);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student account created successfully'),
              backgroundColor: Color(0xFFFF542D),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to student page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentPage()),
          );
        }
      } else {
        // Admin stalls logic
        if (_canteenNameController.text.isEmpty) {
          throw Exception('Canteen name cannot be empty');
        }

        final newStan = Stan(
          stanName: _canteenNameController.text.trim(),
          ownerName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          userId: createdUser.id!,
          description: _descriptionController.text.trim(),
          slot: 'Slot${(await _supabase.from('stalls').select('id')).length + 1}',
        );

        final createdStan = await _stanService.createStan(newStan);

        if (createdStan == null || createdStan.id == null) {
          throw Exception('Failed to create stall');
        }

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin account created successfully'),
              backgroundColor: Color(0xFFFF542D),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to admin page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainAdmin(stanId: createdStan.id!),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userType == 'student';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStudent ? 'Student Information' : 'Canteen Information',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 32),

          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isStudent ? 'Full Name' : 'Owner Name',
              hintText: isStudent ? 'Enter your full name' : 'Enter owner name',
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
                borderSide:
                    const BorderSide(color: Color(0xFFFF542D), width: 2),
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
          if (isStudent)
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
                  borderSide:
                      const BorderSide(color: Color(0xFFFF542D), width: 2),
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
            )
          else ...[
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
                  borderSide:
                      const BorderSide(color: Color(0xFFFF542D), width: 2),
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
                  borderSide:
                      const BorderSide(color: Color(0xFFFF542D), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],

          const SizedBox(height: 24),
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
                borderSide:
                    const BorderSide(color: Color(0xFFFF542D), width: 2),
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
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        await _saveAndSubmit();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Information saved successfully'),
                              backgroundColor: Color(0xFFFF542D),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save information'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
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
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
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
