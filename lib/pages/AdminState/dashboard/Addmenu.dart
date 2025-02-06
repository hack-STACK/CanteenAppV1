import 'dart:io';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/Services/feature/cropImage.dart';
import 'package:kantin/Models/menus.dart'; // Import the Menu model
import 'package:kantin/pages/AdminState/dashboard/addonsPage.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase Storage

class AddMenuScreen extends StatefulWidget {
  const AddMenuScreen({super.key, required this.standId, this.initialImage});
  final int standId;
  final XFile? initialImage;

  @override
  _AddMenuScreenState createState() => _AddMenuScreenState();
}

enum FilterType { none, grayscale, sepia }

class _AddMenuScreenState extends State<AddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  // Store the image locally.
  XFile? _selectedImage;
  // Current filter selection.
  FilterType _selectedFilter = FilterType.none;

  // FoodService instance
  final FoodService _foodService = FoodService();

  @override
  void initState() {
    super.initState();
    // If an initial image is passed, store it.
    _selectedImage = widget.initialImage;
  }

  // Validation methods.
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid price';
    }
    return null;
  }

  /// Opens a bottom sheet with options to pick a new image.
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text("Camera"),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                      _selectedFilter = FilterType.none;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _selectedImage = image;
                      _selectedFilter = FilterType.none;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens a bottom sheet with image editing options.
  void _showImageEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.crop),
                title: const Text("Crop / Resize"),
                onTap: () async {
                  Navigator.pop(context);
                  await _cropImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter),
                title: const Text("Apply Filter"),
                onTap: () {
                  Navigator.pop(context);
                  _showFilterOptions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Change Image"),
                onTap: () {
                  Navigator.pop(context);
                  _showImagePickerOptions();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Crop image using image_cropper.
  Future<void> _cropImage() async {
    if (_selectedImage == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropperWidget(
          imageFile: File(_selectedImage!.path),
          onImageCropped: (croppedFile) {
            if (croppedFile != null) {
              setState(() {
                _selectedImage = XFile(croppedFile.path);
                _selectedFilter = FilterType.none;
              });
            }
          },
        ),
      ),
    );
  }

  /// Opens a bottom sheet to choose a filter.
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.filter_none),
                title: const Text("No Filter"),
                onTap: () {
                  setState(() {
                    _selectedFilter = FilterType.none;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_b_and_w),
                title: const Text("Grayscale"),
                onTap: () {
                  setState(() {
                    _selectedFilter = FilterType.grayscale;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.filter_vintage),
                title: const Text("Sepia"),
                onTap: () {
                  setState(() {
                    _selectedFilter = FilterType.sepia;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Returns a ColorFilter matrix based on the selected filter.
  ColorFilter _getColorFilter() {
    switch (_selectedFilter) {
      case FilterType.grayscale:
        return const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.sepia:
        return const ColorFilter.matrix(<double>[
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case FilterType.none:
      default:
        return const ColorFilter.matrix(<double>[
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
    }
  }

  /// Upload image to Supabase Storage and return the URL.
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    final file = File(_selectedImage!.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      final response = await Supabase.instance.client.storage
          .from('menu_images') // Replace with your bucket name
          .upload(fileName, file);

      // ✅ Fix: Don't treat a non-null response as an error
      if (response == null) {
        throw Exception('Upload failed: No response from Supabase');
      }

      // ✅ Correct way to get the public URL
      final imageUrl = Supabase.instance.client.storage
          .from('menu_images')
          .getPublicUrl(fileName);

      print('Image uploaded successfully: $imageUrl'); // Debug log
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Handle form submission.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Uploading image...'), duration: Duration(seconds: 1)),
    );

    try {
      // Upload the image
      final imageUrl = await _uploadImage();

      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to upload image. Please try again.')),
        );
        return;
      }


      // Create a Menu object
      final menu = Menu(
        id: null,
        foodName: _nameController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        type: _categoryController.text.trim(),
        photo: imageUrl,
        description: _descriptionController.text.trim(),
        stallId: widget.standId,
      );

      // Show progress message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving menu item...')),
      );

      // Save the menu item using FoodService
      final createdMenu = await _foodService.createMenu(menu);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu item added successfully!')),
      );

      // Clear the form for next input
      _nameController.clear();
      _priceController.clear();
      _categoryController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: const Color(0xFFFF542D),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Menu Item',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontSize: 28,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill in the details below to add a new menu item',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 24),
                      // Image Upload Section with edit overlay.
                      GestureDetector(
                        onTap: _selectedImage == null
                            ? _showImagePickerOptions
                            : _showImageEditOptions,
                        child: Stack(
                          children: [
                            Container(
                              height: 240,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: ColorFiltered(
                                        colorFilter: _getColorFilter(),
                                        child: Image.file(
                                          File(_selectedImage!.path),
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Upload Image',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            // Show an edit icon if an image is selected.
                            if (_selectedImage != null)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: FloatingActionButton.small(
                                  backgroundColor: Colors.white,
                                  onPressed: _showImageEditOptions,
                                  child: const Icon(
                                    Icons.edit,
                                    color: Color(0xFFFF542D),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Form Fields
                      _buildTextField(
                        controller: _nameController,
                        label: 'Item Name',
                        hint: 'Enter item name',
                        validator: _validateRequired,
                        icon: Icons.restaurant_menu,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _priceController,
                        label: 'Price',
                        hint: 'Enter price',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: _validatePrice,
                        icon: Icons.attach_money,
                        prefix: Text('\$ ',
                            style: TextStyle(color: Colors.grey.shade700)),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter item description',
                        maxLines: 4,
                        validator: _validateRequired,
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _categoryController,
                        label: 'Category',
                        hint: 'Select or enter category',
                        validator: _validateRequired,
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 24),
                      // Add-ons Section
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFFF542D),
                          ),
                          title: const Text('Add Optional Add-ons'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            //Still error
                            MenuAddonsScreen(menuId: 0 , foodService: _foodService);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF542D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Add to Menu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField ({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            prefix: prefix,
            filled: true,
            fillColor: Colors.white,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
