import 'dart:typed_data';
import 'package:cropperx/cropperx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ImageCropperScreen extends StatefulWidget {
  final List<String> imageAssets;

  const ImageCropperScreen({super.key, required this.imageAssets});

  @override
  _ImageCropperScreenState createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  final GlobalKey _cropperKey = GlobalKey(debugLabel: 'cropperKey');
  final List<Uint8List> _imageDataList = [];
  bool _loadingImage = false;
  int _currentImage = 0;
  Uint8List? _croppedData;

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    setState(() {
      _loadingImage = true;
    });
    for (final assetName in widget.imageAssets) {
      try {
        final assetData = await rootBundle.load(assetName);
        _imageDataList.add(assetData.buffer.asUint8List());
      } catch (e) {
        _showErrorDialog('Failed to load image: $assetName');
      }
    }
    setState(() {
      _loadingImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Your Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _croppedData != null ? _saveCroppedImage : null,
          ),
        ],
      ),
      body: _loadingImage
          ? const Center(child: CircularProgressIndicator())
          : _imageDataList.isEmpty
              ? const Center(child: Text('No images available.'))
              : Column(
                  children: [
                    _buildImageThumbnails(),
                    SizedBox(
                      height: 500,
                      child: Cropper(
                        cropperKey: _cropperKey,
                        image: Image.memory(_imageDataList[_currentImage]),
                        onScaleStart: (details) {
                          // Handle scale start
                        },
                        onScaleUpdate: (details) {
                          // Handle scale update
                        },
                        onScaleEnd: (details) {
                          // Handle scale end
                        },
                      ),
                    ),
                    if (_croppedData != null) Image.memory(_croppedData!),
                    ElevatedButton(
                      onPressed: () async {
                        final croppedImage =
                            await Cropper.crop(cropperKey: _cropperKey);
                        if (croppedImage != null) {
                          setState(() {
                            _croppedData = croppedImage;
                          });
                        }
                      },
                      child: const Text('Crop Image'),
                    ),
                  ],
                ),
    );
  }

  Widget _buildImageThumbnails() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imageDataList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentImage = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _currentImage == index ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Image.memory(
                _imageDataList[index],
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveCroppedImage() {
    if (_croppedData != null) {
      // Handle the cropped image (e.g., upload it or save it)
      print('Cropped image data: ${_croppedData!.lengthInBytes} bytes');
      _showSuccessDialog('Cropped image saved successfully!');
    } else {
      _showErrorDialog('No cropped image to save.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
