import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final Function(File?) onImageCropped;

  const ImageCropperWidget({
    Key? key,
    required this.imageFile,
    required this.onImageCropped,
  }) : super(key: key);

  @override
  _ImageCropperWidgetState createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  final CropController _cropController = CropController();
  Uint8List? _imageBytes;
  double? _aspectRatio = 1.0; // Default aspect ratio

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  /// Load image bytes asynchronously
  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    } catch (e) {
      print('Error loading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cropController.crop(),
            tooltip: 'Reset Crop',
          ),
        ],
      ),
      body: _imageBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Crop(
                    image: _imageBytes!,
                    controller: _cropController,
                    aspectRatio: _aspectRatio, // Apply aspect ratio
                    withCircleUi:
                        false, // Set to true if you want circular cropping
                    interactive: true,
                    onCropped: (dynamic result) async {
                      if (result is CropSuccess) {
                        try {
                          final Uint8List croppedBytes = result.croppedImage;
                          final croppedFile =
                              File('${widget.imageFile.path}_cropped.png');
                          await croppedFile.writeAsBytes(croppedBytes);
                          widget.onImageCropped(croppedFile);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          print('Error saving cropped image: $e');
                        }
                      } else {
                        print('Unexpected result type: ${result.runtimeType}');
                      }
                    },
                  ),
                ),
                _buildAspectRatioSelector(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _rotateImage(true);
                          print('Rotate Left Clicked');
                        },
                        icon: const Icon(Icons.rotate_left),
                        label: const Text('Rotate Left'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          _rotateImage(false);
                          print('Rotate Right Clicked');
                        },
                        icon: const Icon(Icons.rotate_right),
                        label: const Text('Rotate Right'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _cropController.crop(),
                        child: const Text('Crop'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAspectRatioSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _aspectRatioButton('Free', null),
          _aspectRatioButton('1:1', 1.0),
          _aspectRatioButton('16:9', 16 / 9),
          _aspectRatioButton('4:3', 4 / 3),
        ],
      ),
    );
  }

  Widget _aspectRatioButton(String text, double? ratio) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _aspectRatio = ratio;
        });
      },
      child: Text(text),
    );
  }

Future<void> _rotateImage(bool left) async {
  print("Rotating image ${left ? 'left' : 'right'}");
  final imageBytes = await widget.imageFile.readAsBytes();
  img.Image original = img.decodeImage(imageBytes)!;
  img.Image rotated = left
      ? img.copyRotate(original, angle: -90)
      : img.copyRotate(original, angle: 90);

  final rotatedBytes = img.encodePng(rotated);
  setState(() {
    _imageBytes = Uint8List.fromList(rotatedBytes);
  });
}

}
