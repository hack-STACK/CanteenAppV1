import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/Services/feature/cropImage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String stallId;

  const EditProfileScreen({
    super.key,
    required this.initialData,
    required this.stallId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stallNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _stallNameController =
        TextEditingController(text: widget.initialData['stallName']);
    _ownerNameController =
        TextEditingController(text: widget.initialData['ownerName']);
    _phoneController = TextEditingController(text: widget.initialData['phone']);
    _descriptionController =
        TextEditingController(text: widget.initialData['description']);
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        // Show image cropper
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCropperWidget(
              imageFile: File(image.path),
              onImageCropped: (File? croppedFile) {
                if (croppedFile != null && mounted) {
                  setState(() {
                    _imageFile = croppedFile;
                  });
                }
              },
            ),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String? imageUrl;

      if (_imageFile != null) {
        final fileName =
            'stall_${widget.stallId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Delete existing image if it exists
        if (widget.initialData['image_url'] != null) {
          try {
            final oldFileName = widget.initialData['image_url'].split('/').last;
            await supabase.storage.from('stall-images').remove([oldFileName]);
          } catch (e) {
            debugPrint('Error deleting old image: $e');
          }
        }

        // Upload new image
        await supabase.storage
            .from('stall-images')
            .upload(fileName, _imageFile!);

        // Get the public URL
        imageUrl = supabase.storage.from('stall-images').getPublicUrl(fileName);
        debugPrint('New image URL: $imageUrl'); // Debug line
      }

      // Update stall data
      final updateData = {
        'nama_stalls': _stallNameController.text,
        'nama_pemilik': _ownerNameController.text,
        'no_telp': _phoneController.text,
        'deskripsi': _descriptionController.text,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      debugPrint('Updating stall with data: $updateData'); // Debug line

      await supabase.from('stalls').update(updateData).eq('id', widget.stallId);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e'); // Debug line
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImagePicker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade300,
                Colors.blue.shade600,
              ],
            ),
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog, // Changed to show dialog
              child: Stack(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.initialData['image_url'] != null
                              ? NetworkImage(widget.initialData['image_url'])
                                  as ImageProvider
                              : const AssetImage('assets/default_profile.png')),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Profile Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
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
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFormField(
                      label: 'Stall Name',
                      controller: _stallNameController,
                      icon: Icons.store,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter stall name'
                          : null,
                    ),
                    _buildFormField(
                      label: 'Owner Name',
                      controller: _ownerNameController,
                      icon: Icons.person,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter owner name'
                          : null,
                    ),
                    _buildFormField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter phone number'
                          : null,
                    ),
                    _buildFormField(
                      label: 'Description',
                      controller: _descriptionController,
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
