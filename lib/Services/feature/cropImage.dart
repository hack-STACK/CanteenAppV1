import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final Function(File?) onImageCropped;

  const ImageCropperWidget(
      {Key? key, required this.imageFile, required this.onImageCropped})
      : super(key: key);

  @override
  _ImageCropperWidgetState createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  final CropController _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Image')),
      body: Column(
        children: [
          Expanded(
            child: Crop(
                image: File(widget.imageFile.path).readAsBytesSync(),
                controller: _cropController,
                onCropped: (croppedData) async {
                  final croppedBytes =
                      croppedData as Uint8List; // Konversi hasil crop
                  final croppedFile =
                      File('${widget.imageFile.path}_cropped.png');

                  await croppedFile.writeAsBytes(croppedBytes);
                  widget.onImageCropped(croppedFile);
                  Navigator.pop(context);
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _cropController.crop(),
              child: const Text('Crop'),
            ),
          ),
        ],
      ),
    );
  }
}
