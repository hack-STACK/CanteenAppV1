import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Component/My_header.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/pages/AdminState/AdminPage.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PersonalInfoScreen extends StatelessWidget {
  final String role;
  final String firebaseUid;
  const PersonalInfoScreen(
      {super.key, required this.role, required this.firebaseUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
    super.key,
    required this.userType,
    required this.firebaseUid,
  });

  @override
  _AdaptiveRegistrationFormState createState() =>
      _AdaptiveRegistrationFormState();
}

class _AdaptiveRegistrationFormState extends State<AdaptiveRegistrationForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _canteenNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _canteenNameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _isLoading = false;
  final _supabase = Supabase.instance.client;
  final _stanService = StanService();
  bool _hasError = false;
  String _errorMessage = '';
  int _activeFieldCount = 0;
  int _completedFieldCount = 0;

  late AnimationController _animationController;

  // Define focus colors
  Color _nameHintColor = Colors.grey;
  Color _addressHintColor = Colors.grey;
  Color _phoneHintColor = Colors.grey;
  Color _canteenNameHintColor = Colors.grey;
  Color _descriptionHintColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _loadSavedData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Setup focus listeners to change icon colors
    _nameFocusNode.addListener(() {
      setState(() {
        _nameHintColor = _nameFocusNode.hasFocus
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;
      });
    });

    _addressFocusNode.addListener(() {
      setState(() {
        _addressHintColor = _addressFocusNode.hasFocus
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;
      });
    });

    _phoneFocusNode.addListener(() {
      setState(() {
        _phoneHintColor = _phoneFocusNode.hasFocus
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;
      });
    });

    _canteenNameFocusNode.addListener(() {
      setState(() {
        _canteenNameHintColor = _canteenNameFocusNode.hasFocus
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;
      });
    });

    _descriptionFocusNode.addListener(() {
      setState(() {
        _descriptionHintColor = _descriptionFocusNode.hasFocus
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;
      });
    });

    // Set up field change listeners to update progress
    _nameController.addListener(_updateProgress);
    _phoneController.addListener(_updateProgress);
    _addressController.addListener(_updateProgress);
    _canteenNameController.addListener(_updateProgress);
    _descriptionController.addListener(_updateProgress);

    // Initialize required fields count
    _activeFieldCount = widget.userType == 'student'
        ? 3
        : 3; // Name, Phone + Address for students OR Name, Phone, Canteen Name for admins
  }

  void _updateProgress() {
    int completed = 0;
    if (_nameController.text.isNotEmpty) completed++;
    if (_phoneController.text.isNotEmpty) completed++;

    if (widget.userType == 'student') {
      if (_addressController.text.isNotEmpty) completed++;
    } else {
      if (_canteenNameController.text.isNotEmpty) completed++;
    }

    if (mounted) {
      setState(() {
        _completedFieldCount = completed;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _canteenNameController.dispose();
    _descriptionController.dispose();

    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _phoneFocusNode.dispose();
    _canteenNameFocusNode.dispose();
    _descriptionFocusNode.dispose();

    _animationController.dispose();
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

    // Update progress after loading data
    _updateProgress();
  }

  Future<void> _saveAndSubmit() async {
    // Validate the form
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Initialize services
      final userService = UserService();
      final studentService = StudentService();
      final stanService = StanService();

      // Ensure you have the correct Firebase UID
      final firebaseUid = widget.firebaseUid;

      // Update the user's profile completion status
      final updatedUserData = {
        'has_completed_Profile': true, // Mark the form as completed
        // Include any additional fields from the form here
      };

      // Update the user record in Supabase
      final updatedUserResponse = await userService.updateUserByFirebaseUid(
        firebaseUid,
        updatedUserData,
      );

      // Get the user ID from the updated response
      final int userId = updatedUserResponse['id'] as int;

      // Handle role-specific logic
      if (widget.userType == 'student') {
        // Create student using StudentModel - remove explicit id
        final studentData = StudentModel(
          // Remove the id: 0 line completely to let the database assign an ID
          studentName: _nameController.text.trim(),
          studentAddress: _addressController.text.trim(),
          studentPhoneNumber: _phoneController.text.trim(),
          userId: userId,
          studentImage: '', // Handle image upload separately if needed
        );

        // Use StudentService to create student
        await studentService.createStudent(studentData);

        // Update Firestore to mark the profile as completed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUid)
            .update({'hasCompletedProfile': true});

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Student account created successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate to the student page
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const StudentPage()),
              (Route) => false);
        }
      } else if (widget.userType == 'admin_stalls') {
        // Admin stalls logic
        if (_canteenNameController.text.isEmpty) {
          throw Exception('Canteen name cannot be empty.');
        }

        // Create a new stall
        final newStan = Stan(
          id: 0, // Provide a valid id here
          stanName: _canteenNameController.text.trim(),
          ownerName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          userId: userId,
          description: _descriptionController.text.trim(),
          slot:
              'Slot ${(await _supabase.from('stalls').select('id')).length + 1}', // Generate a unique slot
        );

        final createdStan = await stanService.createStan(newStan);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Admin account created successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate to the admin page
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MainAdmin(stanId: createdStan.id),
              ),
              (Route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });

        // Animate error message
        _animationController
            .forward()
            .then((_) => _animationController.reverse());

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStudent
                            ? 'Student Information'
                            : 'Canteen Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ).animate().fadeIn(duration: Duration(milliseconds: 500)),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete your profile',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      isStudent ? Icons.school : Icons.restaurant,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ).animate().scale(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                      ),
                ],
              ),

              const SizedBox(height: 20),

              // Progress indicator
              LinearProgressIndicator(
                value: _completedFieldCount / _activeFieldCount,
                backgroundColor: Colors.grey[200],
                color: theme.colorScheme.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ).animate().fadeIn().slideX(),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '${_completedFieldCount}/${_activeFieldCount} fields completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Error message with animation
              if (_hasError)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      transform: Matrix4.translationValues(
                        5 * _animationController.value,
                        0,
                        0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Fields Section Title
              Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100)),

              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: InputDecoration(
                  labelText: isStudent ? 'Full Name' : 'Owner Name',
                  hintText:
                      isStudent ? 'Enter your full name' : 'Enter owner name',
                  prefixIcon: Icon(Icons.person_outline, color: _nameHintColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter the name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ).animate().fadeIn(delay: Duration(milliseconds: 100)),

              const SizedBox(height: 20),

              // Conditional fields based on user type
              if (isStudent) ...[
                TextFormField(
                  controller: _addressController,
                  focusNode: _addressFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter your address',
                    prefixIcon:
                        Icon(Icons.home_outlined, color: _addressHintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: Duration(milliseconds: 200))
              ] else ...[
                // Business section title
                const SizedBox(height: 8),
                Text(
                  'Business Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 150)),
                const SizedBox(height: 6),
                const Divider(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _canteenNameController,
                  focusNode: _canteenNameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Canteen Name',
                    hintText: 'Enter canteen name',
                    prefixIcon: Icon(Icons.store_outlined,
                        color: _canteenNameHintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter canteen name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: Duration(milliseconds: 200)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter canteen description',
                    prefixIcon: Icon(Icons.description_outlined,
                        color: _descriptionHintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: Duration(milliseconds: 300)),
              ],

              const SizedBox(height: 20),

              // Contact section title - for both user types
              if (!isStudent) const SizedBox(height: 8),
              Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: isStudent ? 250 : 350)),
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: _phoneHintColor),
                  suffixIcon: Icon(
                    Icons.check_circle,
                    color: _phoneController.text.isNotEmpty
                        ? Colors.green
                        : Colors.transparent,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: isStudent ? 300 : 400)),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Saving...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Complete Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: isStudent ? 400 : 500))
                  .slideY(
                    begin: 0.5,
                    end: 0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutQuad,
                  ),

              if (!_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'You can update your information ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextSpan(
                            text: 'later',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(
                    delay: Duration(milliseconds: isStudent ? 500 : 600)),
            ],
          ),
        ),
      ),
    );
  }
}
