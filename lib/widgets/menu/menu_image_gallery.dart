import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kantin/Services/feature/cropImage.dart';

class MenuImageGallery extends StatefulWidget {
  final List<String> images;
  final Function(XFile) onImagePicked;
  final Function(int) onImageRemoved;
  final bool isLoading;

  const MenuImageGallery({
    super.key,
    required this.images,
    required this.onImagePicked,
    required this.onImageRemoved,
    this.isLoading = false,
  });

  @override
  State<MenuImageGallery> createState() => _MenuImageGalleryState();
}

class _MenuImageGalleryState extends State<MenuImageGallery> {
  Future<void> _pickImage() async {
    try {
      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () => _pickAndProcessImage(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () => _pickAndProcessImage(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      _showError('Error showing image picker: $e');
    }
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        Navigator.pop(context); // Close bottom sheet

        // Navigate to crop screen
        final croppedImage = await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => ImageCropperWidget(
              imageFile: File(image.path),
              onImageCropped: (file) {
                if (file != null) {
                  widget.onImagePicked(XFile(file.path));
                }
                Navigator.pop(context);
              },
              aspectRatio: 4 / 3, // Changed to 4/3
            ),
          ),
        );

        if (croppedImage != null) {
          widget.onImagePicked(XFile(croppedImage.path));
        }
      }
    } catch (e) {
      _showError('Error picking/cropping image: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3, // Changed from 1 to 4/3
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.isEmpty ? 1 : widget.images.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.images.length) {
                return _buildAddImageButton();
              }
              return _buildImageViewer(index);
            },
          ),
          if (widget.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo, size: 48),
            SizedBox(height: 8),
            Text('Add Photo'),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer(int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: widget.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error_outline, size: 32),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: IconButton.filled(
            icon: const Icon(Icons.delete),
            onPressed: () => widget.onImageRemoved(index),
          ),
        ),
      ],
    );
  }
}
