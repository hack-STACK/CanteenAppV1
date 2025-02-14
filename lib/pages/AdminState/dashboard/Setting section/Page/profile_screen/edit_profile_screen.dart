import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/Services/feature/cropImage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String stallId;

  const EditProfileScreen({
    Key? key,
    required this.initialData,
    required this.stallId,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _stallNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  
  // Remove duplicate declarations and consolidate image-related variables
  File? _imageFile;
  File? _bannerImageFile;
  String? _currentProfileImage;
  String? _currentBannerImage;
  bool _hasExistingProfile = false;
  bool _hasExistingBanner = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // Add custom colors
  final Color primaryColor = const Color(0xFF2D3436);
  final Color accentColor = const Color(0xFF00B894);
  final Color backgroundColor = const Color(0xFFF5F6FA);
  final Color textColor = const Color(0xFF2D3436);

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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Initialize existing images with proper URLs
    _currentProfileImage = widget.initialData['imageUrl'] ?? widget.initialData['image_url'];
    _currentBannerImage = widget.initialData['bannerUrl'] ?? widget.initialData['Banner_img'];
    _hasExistingProfile = _currentProfileImage != null && _currentProfileImage!.isNotEmpty;
    _hasExistingBanner = _currentBannerImage != null && _currentBannerImage!.isNotEmpty;

    debugPrint('Profile Image URL: $_currentProfileImage'); // Debug line
    debugPrint('Banner Image URL: $_currentBannerImage'); // Debug line
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
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
                  _updateProfileImage(croppedFile);
                }
              },
              aspectRatio: 1.0, // Square ratio for profile picture
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

  Future<void> _pickBannerImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCropperWidget(
              imageFile: File(image.path),
              onImageCropped: (File? croppedFile) {
                if (croppedFile != null && mounted) {
                  setState(() {
                    _bannerImageFile = croppedFile;
                  });
                  _updateBannerImage(croppedFile);
                }
              },
              aspectRatio: 16 / 9, // Banner ratio
            ),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking banner image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking banner image: $e')),
        );
      }
    }
  }

  Future<void> _updateProfileImage(File imageFile) async {
    try {
      setState(() => _isLoading = true);
      final supabase = Supabase.instance.client;
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Create unique filename
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'stall_${widget.stallId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Delete existing image if it exists
      if (widget.initialData['image_url'] != null) {
        try {
          final oldFileName = widget.initialData['image_url'].split('/').last;
          await supabase.storage.from('stall-images').remove([oldFileName]);
        } catch (e) {
          debugPrint('Error deleting old image: $e');
        }
      }

      // Upload new image with proper content type
      await supabase.storage.from('stall-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Get public URL
      final imageUrl = supabase.storage.from('stall-images').getPublicUrl(fileName);

      // Update database
      await supabase.from('stalls')
          .update({'image_url': imageUrl})
          .eq('id', widget.stallId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
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

  Future<void> _updateBannerImage(File imageFile) async {
    try {
      setState(() => _isLoading = true);
      final supabase = Supabase.instance.client;
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Create unique filename
      final fileExt = imageFile.path.split('.').last;
      final fileName = 'banner_${widget.stallId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Delete existing banner if it exists
      if (widget.initialData['Banner_img'] != null) {
        try {
          final oldFileName = widget.initialData['Banner_img'].split('/').last;
          await supabase.storage.from('banner-images').remove([oldFileName]);
        } catch (e) {
          debugPrint('Error deleting old banner: $e');
        }
      }

      // Upload new banner with proper content type
      await supabase.storage.from('banner-images').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Get public URL
      final bannerUrl = supabase.storage.from('banner-images').getPublicUrl(fileName);

      // Update database
      await supabase.from('stalls')
          .update({'Banner_img': bannerUrl})
          .eq('id', widget.stallId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner image updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating banner image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating banner image: $e'),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String? imageUrl;
      String? bannerImageUrl;

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

      if (_bannerImageFile != null) {
        final bannerFileName =
            'banner_${widget.stallId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Delete existing banner image if it exists
        if (widget.initialData['Banner_img'] != null) {
          try {
            final oldBannerFileName = widget.initialData['Banner_img'].split('/').last;
            await supabase.storage.from('banner-images').remove([oldBannerFileName]);
          } catch (e) {
            debugPrint('Error deleting old banner image: $e');
          }
        }

        // Upload new banner image
        await supabase.storage
            .from('banner-images')
            .upload(bannerFileName, _bannerImageFile!);

        // Get the public URL
        bannerImageUrl = supabase.storage.from('banner-images').getPublicUrl(bannerFileName);
        debugPrint('New banner image URL: $bannerImageUrl'); // Debug line
      }

      // Update stall data
      final updateData = {
        'nama_stalls': _stallNameController.text,
        'nama_pemilik': _ownerNameController.text,
        'no_telp': _phoneController.text,
        'deskripsi': _descriptionController.text,
        if (imageUrl != null) 'image_url': imageUrl,
        if (bannerImageUrl != null) 'Banner_img': bannerImageUrl,
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

  Future<void> _showBannerImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Banner Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickBannerImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickBannerImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerWithProfile() {
    return SliverAppBar(
      expandedHeight: 350, // Increased height to accommodate profile section
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          clipBehavior: Clip.none, // Allow content to overflow
          children: [
            // Banner Image
            Positioned.fill(
              child: _bannerImageFile != null
                  ? Image.file(_bannerImageFile!, fit: BoxFit.cover)
                  : (_currentBannerImage != null && _currentBannerImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _currentBannerImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accentColor.withOpacity(0.8),
                                  primaryColor.withOpacity(0.8),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withOpacity(0.8),
                                primaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                        )),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Change Cover Button
            Positioned(
              top: 80,
              right: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: _showBannerImageSourceDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, size: 20, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Change Cover',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Profile Section
            Positioned(
              bottom: 40, // Adjusted to show full profile image
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    SizedBox(
                      width: 120, // Fixed width for profile section
                      height: 120, // Fixed height for profile section
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: Colors.white,
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider<Object>?
                                  : (_currentProfileImage != null && _currentProfileImage!.isNotEmpty
                                      ? NetworkImage(_currentProfileImage!)
                                      : null),
                              child: _imageFile == null && 
                                     (_currentProfileImage == null || _currentProfileImage!.isEmpty)
                                  ? Text(
                                      widget.initialData['ownerName'][0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(20),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialData['ownerName'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.initialData['stallName'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildBannerWithProfile(),
          SliverToBoxAdapter(
            child: SizedBox(height: 60), // Increased spacing for profile overlap
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24), // Add padding here
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form( // Changed from child: to proper child property
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
              ),
            ]),
          ),
        ],
      ),
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
      child: FadeTransition(
        opacity: _fadeInAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              validator: validator,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String? currentImage, File? imageFile, String placeholder) {
    if (imageFile != null) {
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
      );
    } else if (currentImage != null && currentImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: currentImage,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red),
              Text('Error loading image'),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(placeholder),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    try {
      // Upload new images if selected
      String? newProfileUrl = _currentProfileImage;
      String? newBannerUrl = _currentBannerImage;

      if (_imageFile != null) { // Changed from _profileImageFile to _imageFile
        newProfileUrl = await _uploadImage(_imageFile!, 'profile');
      }

      if (_bannerImageFile != null) {
        newBannerUrl = await _uploadImage(_bannerImageFile!, 'banner');
      }

      // Update the result data with new image URLs
      final Map<String, dynamic> resultData = {
        ...widget.initialData,
        'imageUrl': newProfileUrl,
        'bannerUrl': newBannerUrl,
        // Add other updated fields...
      };

      // Return the updated data
      Navigator.of(context).pop(resultData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  Future<String> _uploadImage(File imageFile, String type) async {
    // Implement your image upload logic here
    // Return the URL of the uploaded image
    // This is just a placeholder - replace with your actual upload code
    return '';
  }
}
