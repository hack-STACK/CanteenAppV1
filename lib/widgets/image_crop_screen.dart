import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class ImageCropScreen extends StatelessWidget {
  final String imagePath;
  final double aspectRatio;

  const ImageCropScreen({
    super.key,
    required this.imagePath,
    this.aspectRatio = 16 / 9,
  });

  Future<String?> _cropImage() async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Changed to 1:1
        compressQuality: 90,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square, // Changed to square
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return croppedFile.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
        actions: [
          TextButton(
            onPressed: () async {
              final croppedPath = await _cropImage();
              if (context.mounted) {
                Navigator.pop(context, croppedPath);
              }
            },
            child: const Text(
              'Crop',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
      ),
    );
  }
}
