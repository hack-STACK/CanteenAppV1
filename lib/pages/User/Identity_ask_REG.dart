import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kantin/Component/my_dropdown.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/Services/Database/firestore.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';

class IdentityAskReg extends StatefulWidget {
  final String role;

  const IdentityAskReg({super.key, required this.role});

  @override
  _IdentityAskRegState createState() => _IdentityAskRegState();
}

class _IdentityAskRegState extends State<IdentityAskReg> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int? _age;
  String? _selectedClass;
  String? _canteenName;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _canteenNameController = TextEditingController();

  final FireStoreService db = FireStoreService();

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

  List<String> _canteenSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchCanteenSlots();
  }

  Future<void> _fetchCanteenSlots() async {
    List<String> slots = await db.getCanteenSlots();
    setState(() {
      _canteenSlots = slots;
    });
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

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorDialog('User  not authenticated.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String documentId = user.uid;

      if (widget.role == 'admin' && _canteenName != null) {
        bool exists = await db.doesCanteenNameExist(_canteenName!);
        if (exists) {
          _showErrorDialog(
              'Canteen name already exists. Please choose another name.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      try {
        String canteenId = '';
        String assignedSlot = '';

        if (widget.role == 'admin') {
          final slotsQuery = await FirebaseFirestore.instance
              .collection('canteen_slots')
              .get();

          if (slotsQuery.docs.length >= 12) {
            _showErrorDialog(
                'Maximum number of canteen slots reached. Cannot register new admin.');
            setState(() {
              _isLoading = false;
            });
            return;
          }

          final canteenDocRef = await FirebaseFirestore.instance
              .collection('canteen_slots')
              .add({'placeholder': true});
          canteenId = canteenDocRef.id;
          assignedSlot = (slotsQuery.docs.length + 1).toString();

          await canteenDocRef.set({
            'canteenId': canteenId,
            ' slotNumber': assignedSlot,
            'adminUid': documentId,
            'canteenName': _canteenName,
            'createdAt': Timestamp.now(),
          });
        }

        Map<String, dynamic> userData = {
          '1_uid': documentId,
          '4_email': user.email,
          '2_name': _name,
          '3_age': _age,
          '8_role': widget.role,
          '9_createdAt': Timestamp.now(),
        };

        if (widget.role == 'student') {
          userData['5_class'] = _selectedClass;
        } else if (widget.role == 'admin') {
          userData['6_slot'] = assignedSlot;
          userData['7_canteenName'] = _canteenName;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .set(userData);

        if (widget.role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentPage()),
          );
        } else if (widget.role == 'admin') {
          final canteenName = await db.getCanteenNameByUid(documentId);
          if (canteenName != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainAdmin()),
            );
          } else {
            _showErrorDialog('Failed to fetch canteen name.');
          }
        }
      } catch (e) {
        _showErrorDialog('Failed to save data: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _canteenNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Registration'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Identity Registration',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    MyTextfield(
                      controller: _nameController,
                      hintText: 'Enter your name',
                      obscureText: false,
                      onSaved: (value) {
                        _name = value!;
                      },
                      hintColor: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    MyTextfield(
                      controller: _ageController,
                      hintText: 'Enter your age',
                      obscureText: false,
                      keyboardInputType: TextInputType.number,
                      onSaved: (value) {
                        _age = int.tryParse(value!);
                      },
                      hintColor: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    if (widget.role == 'admin')
                      MyTextfield(
                        controller: _canteenNameController,
                        hintText: 'Enter Canteen Name',
                        obscureText: false,
                        onSaved: (value) {
                          _canteenName = value!;
                        },
                        hintColor: Colors.grey.shade400,
                      ),
                    if (widget.role == 'student')
                      MyDropdown(
                        value: _selectedClass,
                        hintText: 'Select Class',
                        hintColor: Colors.grey.shade400,
                        items: _studentClasses,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedClass = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a class' : null,
                        onSaved: (value) {
                          _selectedClass = value;
                        },
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30),
                        backgroundColor: Colors.blueGrey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: Text(_isLoading ? 'Submitting ...' : 'Submit',
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
