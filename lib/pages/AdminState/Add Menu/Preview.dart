import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final Uint8List croppedImage;
  final Function onUpload;

  const ImagePreview(
      {super.key, required this.croppedImage, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cropped Image Preview'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.memory(croppedImage),
          const SizedBox(height: 20),
          const Text('Do you want to upload this image?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onUpload(); // Call the upload function
            Navigator.pop(context);
          },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
