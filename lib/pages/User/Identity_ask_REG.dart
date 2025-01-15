import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kantin/Component/my_textfield.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';

// ... (Other imports)

class IdentityAskReg extends StatefulWidget {
  final String role;

  const IdentityAskReg({Key? key, required this.role}) : super(key: key);

  @override
  _IdentityAskRegState createState() => _IdentityAskRegState();
}

class _IdentityAskRegState extends State<IdentityAskReg> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  int? _age;
  String? _selectedClass;
  String? _selectedSlot;
  bool _isLoading = false;

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

  final List<String> _canteenSlots = [
    'Canteen Slot 1',
    'Canteen Slot 2',
    'Canteen Slot 3',
    'Canteen Slot 4',
    'Canteen Slot 5',
    'Canteen Slot 6',
    'Canteen Slot 7',
    'Canteen Slot 8',
    'Canteen Slot 9',
    'Canteen Slot 10',
  ];

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

  void _submit() async {
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

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(documentId)
            .set({
          'name': _name,
          'age': _age,
          'class': widget.role == 'student' ? _selectedClass : null,
          'slot': widget.role == 'admin' ? _selectedSlot : null,
          'createdAt': Timestamp.now(),
        });

        if (widget.role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentPage()),
          );
        } else if (widget.role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Identity Registration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  MyTextfield(
                    controller: TextEditingController(),
                    hintText: 'Name',
                    obscureText: false,
                    hintColor: Colors.grey,
                    onSaved: (value) {
                      _name = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  MyTextfield(
                    controller: TextEditingController(),
                    hintText: 'Age',
                    obscureText: false,
                    hintColor: Colors.grey,
                    keyboardInputType: TextInputType.number,
                    onSaved: (value) {
                      _age = int.tryParse(value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  if (widget.role == 'student') ...[
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedClass,
                      items: _studentClasses
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedClass = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a class' : null,
                    ),
                  ] else if (widget.role == 'admin') ...[
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Select Canteen Slot',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedSlot,
                      items: _canteenSlots
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSlot = newValue;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select a slot' : null,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text('Submit', style: TextStyle(fontSize: 16)),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
