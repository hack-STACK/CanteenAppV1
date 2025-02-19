import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/utils/avatar_generator.dart';

class StudentProfilePage extends StatefulWidget {
  final StudentModel student;
  
  const StudentProfilePage({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final StudentService _studentService = StudentService();
  bool _isEditing = false;
  bool _isLoading = false;
  File? _imageFile;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.studentName);
    _addressController = TextEditingController(text: widget.student.studentAddress);
    _phoneController = TextEditingController(text: widget.student.studentPhoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduce image quality to improve upload speed
        maxWidth: 1024, // Limit image size
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        setState(() {
          _imageFile = File(image.path);
          _isLoading = true;
        });

        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            duration: Duration(seconds: 1),
          ),
        );

        final fileName = 'student_${widget.student.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final imageUrl = await _studentService.uploadStudentImage(image.path, fileName);
        
        if (imageUrl != null && mounted) {
          final updatedStudent = StudentModel(
            id: widget.student.id,
            studentName: widget.student.studentName,
            studentAddress: widget.student.studentAddress,
            studentPhoneNumber: widget.student.studentPhoneNumber,
            userId: widget.student.userId,
            studentImage: imageUrl,
          );

          await _studentService.updateStudent(updatedStudent);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving changes...'),
          duration: Duration(seconds: 1),
        ),
      );

      final updatedStudent = StudentModel(
        id: widget.student.id,
        studentName: _nameController.text.trim(),
        studentAddress: _addressController.text.trim(),
        studentPhoneNumber: _phoneController.text.trim(),
        userId: widget.student.userId,
        studentImage: widget.student.studentImage,
      );

      await _studentService.updateStudent(updatedStudent);
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Widget _buildProfilePicture() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Hero(
          tag: 'profile_${widget.student.id}',
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            child: widget.student.studentImage != null && 
                   widget.student.studentImage!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.student.studentImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return AvatarGenerator.generateStallAvatar(
                          widget.student.studentName,
                          size: 120,
                        );
                      },
                    ),
                  )
                : AvatarGenerator.generateStallAvatar(
                    widget.student.studentName,
                    size: 120,
                  ),
          ),
        ),
        if (!_isLoading)
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                onPressed: _isLoading ? null : _pickImage,
              ),
            ),
          ),
        if (_isLoading)
          const CircularProgressIndicator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfilePicture(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      enabled: _isEditing,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      enabled: _isEditing,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      enabled: _isEditing,
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Save Changes'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}