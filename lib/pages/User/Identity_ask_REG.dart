import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin/Component/my_dropdown.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/UsersModels.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IdentityAskReg extends StatefulWidget {
  final String role;
  const IdentityAskReg({super.key, required this.role});

  @override
  _IdentityAskRegState createState() => _IdentityAskRegState();
}

class _IdentityAskRegState extends State<IdentityAskReg> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final _stanService = StanService();

  String _name = '';
  int? _phoneNumber;
  String? _addresses;
  String? _selectedClass;
  String? _canteenName;
  String? _canteenDescription;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumbercontroller = TextEditingController();
  final TextEditingController _canteenNameController = TextEditingController();
  final TextEditingController _addressesController = TextEditingController();
  final TextEditingController _canteenDescriptionController =
      TextEditingController();

  final List<String> _studentClasses = [
    'Kelas 10 XRPL 1',
    'Kelas 10 XRPL 2',
    'Kelas 11 XRPL 1',
    'Kelas 11 XRPL 2',
    'Kelas 12 XRPL 1',
    'Kelas 12 XRPL 2',
    'Kelas TKJ 1',
    'Kelas TKJ 2',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          widget.role == 'admin' ? Icons.store_rounded : Icons.school_rounded,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          widget.role == 'admin'
              ? 'Canteen Registration'
              : 'Student Registration',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.role == 'admin'
              ? 'Set up your canteen profile'
              : 'Complete your student profile',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentFields() {
    return Column(
      children: [
        MyTextfield(
          controller: _nameController,
          hintText: 'Full Name',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          onSaved: (value) => _name = value ?? '',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextfield(
          controller: _addressesController,
          hintText: 'Addresses',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          keyboardInputType: TextInputType.number,
          onSaved: (value) => _addresses = value ?? '',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextfield(
          controller: _phoneNumbercontroller,
          hintText: 'Phone Number',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          keyboardInputType: TextInputType.number,
          onSaved: (value) => _phoneNumber = int.tryParse(value ?? '') ?? 0,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyDropdown(
          value: _selectedClass,
          hintText: 'Select Class',
          hintColor: Colors.grey.shade400,
          items: _studentClasses,
          onChanged: (String? newValue) {
            setState(() => _selectedClass = newValue);
          },
          validator: (value) => value == null ? 'Please select a class' : null,
          onSaved: (value) => _selectedClass = value,
        ),
      ],
    );
  }

  Widget _buildAdminFields() {
    return Column(
      children: [
        MyTextfield(
          controller: _nameController,
          hintText: 'Owner Name',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          onSaved: (value) => _name = value ?? '',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter owner name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextfield(
          controller: _canteenNameController,
          hintText: 'Canteen Name',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          onSaved: (value) => _canteenName = value ?? '',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter canteen name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextfield(
          controller: _canteenDescriptionController,
          hintText: 'Canteen Description',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          onSaved: (value) => _canteenDescription = value ?? '',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter canteen description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextfield(
          controller: _phoneNumbercontroller,
          hintText: 'Phone Number',
          obscureText: false,
          hintColor: Colors.grey.shade400,
          keyboardInputType: TextInputType.number,
          onSaved: (value) => _phoneNumber = int.tryParse(value ?? '') ?? 0,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _fetchUserData() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User not authenticated.';
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User document does not exist.';
        });
        return;
      }

      final data = userDoc.data();
      if (data == null || data['role'] == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Role not found in user data.';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error fetching user data: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Create an instance of UserService
      final userService = UserService();

      // 1. Check if the username already exists
      final usernameExists =
          await userService.checkUsernameExists(_name.trim());
      if (usernameExists) {
        throw Exception('Username already exists. Please choose another one.');
      }

      // 2. Create the user in the users table without setting the ID
      final userData = UserModel(
        username: _name.trim(),
        password: '', // Handle password securely
        role: widget.role,
      );

      // Insert user and get the created user data back
      final createdUser = await userService.createUser(userData);
      final userId = createdUser.id; // Get the auto-generated user ID

      // 3. Handle role-specific logic
      if (widget.role == 'student') {
        // Create the student entry in the siswa table
        final studentData = {
          'nama_siswa': _name,
          'alamat': _addresses,
          'telp': _phoneNumber,
          'id_user': userId,
          'foto': null,
        };

        // Insert student data into the siswa table
        await _supabase.from('students').insert(studentData);

        // Navigate to the StudentPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const StudentPage()),
        );
      } else if (widget.role == 'admin_stalls') {
        // Admin logic: Create a new stall
// Admin logic: Create a new stall
        if (_canteenName != null && _canteenName!.isNotEmpty) {
          // Debugging: Print the values of the fields
          print('Canteen Name: $_canteenName');
          print('Owner Name: $_name');
          print('Phone Number: $_phoneNumber');
          print('User   ID: $userId');
          print('Canteen Description: $_canteenDescription');

          // Validation: Ensure all required fields are set
          if (_canteenName!.isEmpty) {
            throw Exception('Canteen name is required');
          }
          if (_name.isEmpty) {
            throw Exception('Owner name is required');
          }
          if (_phoneNumber == null) {
            throw Exception('Phone number is required');
          }

          // Create the new Stan object
          final newStan = Stan(
            stanName: _canteenName!,
            ownerName: _name!,
            phone:
                _phoneNumber?.toString() ?? '', // Ensure this is a valid string
            userId:
                userId!, // Use null assertion operator if you are sure userId is not null
            description:
                _canteenDescription ?? '', // Provide a default value if null
            slot:
                'Slot${(await _supabase.from('stalls').select('id')).length + 1}', // Ensure this is always a valid string
          );

          // Debugging: Print the newStan object
          print('New Stan Object: ${newStan.toMap()}');

          // Create the new stall
          final createdStan = await _stanService.createStan(newStan);

          // Navigate to the MainAdmin page only if creation is successful
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainAdmin(
                  stanId: createdStan
                      .id!), // Use null assertion if you're sure id is not null
            ),
          );
        } else {
          throw Exception('Canteen name cannot be empty');
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('Error during registration: $e'); // For debugging
      // Handle the error appropriately, e.g., show a dialog or a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Complete Registration'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width > 600
                      ? 600
                      : double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        if (_hasError)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        widget.role == 'student'
                            ? _buildStudentFields()
                            : _buildAdminFields(),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Complete Registration',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumbercontroller.dispose();
    _canteenNameController.dispose();
    _canteenDescriptionController.dispose();
    super.dispose();
  }
}
