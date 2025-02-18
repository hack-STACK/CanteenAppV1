import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

// Move enum outside class
enum CropImageStatus { ready, cropping, processing, error }

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final Function(File?) onImageCropped;
  final double? aspectRatio;

  const ImageCropperWidget({
    super.key,
    required this.imageFile,
    required this.onImageCropped,
    this.aspectRatio,
  });

  @override
  _ImageCropperWidgetState createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget>
    with SingleTickerProviderStateMixin {
  final CropController _cropController = CropController();
  Uint8List? _imageBytes;
  late double? _aspectRatio;
  late TabController _tabController;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  String _selectedFilter = 'None';
  bool _isSaving = false;

  final Map<String, List<double>> filters = {
    'None': [1, 1, 1],
    'Vintage': [1.2, 0.8, 0.9],
    'Cool': [0.9, 1.1, 1.2],
    'Warm': [1.1, 1.0, 0.9],
    'Dramatic': [1.3, 1.2, 0.8],
    'B&W': [1.0, 0, 0],
  };

  bool _isFilterProcessing = false;
  Uint8List? _originalImageBytes;
  Map<String, bool> _appliedAdjustments = {
    'brightness': false,
    'contrast': false,
    'saturation': false,
    'filter': false,
  };

  // Add debounce timer
  Timer? _debounceTimer;

  // Add adjustment limits and multipliers
  static const double _contrastMultiplier = 0.5;
  static const double _saturationMultiplier = 0.5;
  static const double _brightnessMultiplier =
      2.55; // Proper scaling for -100 to 100 range

  // Add new property to store working copy
  Uint8List? _workingImageBytes;

  // Add new property to track if image is cropped
  bool _isCropped = false;
  Uint8List? _croppedImageBytes;

  // Add new properties for crop control
  bool _isCircularCrop = false;
  final double _cropRadius = 1.0;
  double _rotation = 0.0;
  final double _scale = 1.0;
  String? _activeFilter;

  // Add image state management
  late ValueNotifier<Uint8List?> _currentImage;
  bool _isInitializing = true;

  // Add new properties for crop state management
  final ValueNotifier<Rect?> _cropRect = ValueNotifier<Rect?>(null);
  bool _isCropValid = false;
  final bool _isRotating = false;
  CropImageStatus _cropStatus = CropImageStatus.ready;

  // Add crop state notifier
  final ValueNotifier<bool> _isCropReady = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.aspectRatio;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _currentImage = ValueNotifier<Uint8List?>(null);
    _initializeImage();
    _initCrop();
  }

  void _initCrop() {
    // Initialize crop here if needed
    _isCropReady.value = true;
  }

  Future<void> _initializeImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _originalImageBytes = bytes;
        _workingImageBytes = bytes;
        _currentImage.value = bytes;
        _isInitializing = false;
      });
    } catch (e) {
      _showError('Error loading image: $e');
    }
  }

  @override
  void dispose() {
    _isCropReady.dispose();
    _cropRect.dispose();
    _currentImage.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateCurrentImage(Uint8List newImage) {
    setState(() {
      _imageBytes = newImage;
      _workingImageBytes = newImage;
      _currentImage.value = newImage;
    });
  }

  Future<void> _handleCrop(CropResult result) async {
    try {
      setState(() => _cropStatus = CropImageStatus.cropping);

      if (result is CropSuccess) {
        final Uint8List croppedData = result.croppedImage;

        // Validate cropped image
        if (croppedData.isEmpty) {
          throw Exception('Invalid crop result');
        }

        // Process the image with current settings
        var processedImage = await _processCroppedImage(croppedData);

        // Create temp file
        final tempFile = await _saveToTempFile(processedImage);

        // Update states
        _updateImageStates(processedImage, croppedData);

        widget.onImageCropped(tempFile);

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw Exception('Crop failed');
      }
    } catch (e) {
      debugPrint('Error in _handleCrop: $e');
      _handleCropError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _cropStatus = CropImageStatus.ready);
      }
    }
  }

  Future<Uint8List> _processCroppedImage(Uint8List imageData) async {
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception('Failed to decode cropped image');

    var processed = image;

    // Apply rotation if needed
    if (_rotation != 0) {
      processed = img.copyRotate(processed, angle: _rotation.round());
    }

    // Reapply active filter if exists
    if (_activeFilter != null && _activeFilter != 'None') {
      processed = await _applyFilterToImage(
              Uint8List.fromList(img.encodeJpg(processed)), _activeFilter!)
          .then((bytes) => img.decodeImage(bytes)!);
    }

    return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
  }

  void _updateImageStates(Uint8List processedImage, Uint8List originalCropped) {
    setState(() {
      _isCropped = true;
      _croppedImageBytes = processedImage;
      _workingImageBytes = processedImage;
      _imageBytes = processedImage;
      _originalImageBytes = originalCropped; // Store unfiltered version
      _rotation = 0;
    });
  }

  void _handleCropError(String error) {
    setState(() {
      _cropStatus = CropImageStatus.error;
      _isCropValid = false;
    });
    _showError('Failed to crop image: $error');
  }

  Future<Uint8List> _processImage(Uint8List imageData) async {
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception('Failed to decode image');

    var processedImage = image;
    if (_rotation != 0) {
      processedImage = img.copyRotate(processedImage, angle: _rotation.round());
    }

    return Uint8List.fromList(img.encodeJpg(processedImage, quality: 90));
  }

  Future<File> _saveToTempFile(Uint8List imageData) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageData);
    return tempFile;
  }

  Future<void> _applyImageAdjustments(Uint8List imageData) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      if (_isFilterProcessing) return;

      try {
        setState(() => _isFilterProcessing = true);

        final sourceBytes = _isCropped ? _croppedImageBytes! : imageData;
        final image = img.decodeImage(sourceBytes);
        if (image == null) return;

        var adjustedImage = image.clone();

        // Updated brightness adjustment logic
        if (_appliedAdjustments['brightness']! && _brightness != 0) {
          // Convert brightness from -100..100 to proper pixel adjustment
          final brightnessValue = (_brightness * _brightnessMultiplier).round();
          adjustedImage = img.adjustColor(
            adjustedImage,
            brightness: brightnessValue / 255, // Normalize to -1.0 to 1.0 range
          );
        }

        if (_appliedAdjustments['contrast']! && _contrast != 1) {
          final scaledContrast = (_contrast - 1) * _contrastMultiplier + 1;
          adjustedImage = img.adjustColor(
            adjustedImage,
            contrast: scaledContrast.clamp(0.5, 1.5), // Limit contrast range
          );
        }

        if (_appliedAdjustments['saturation']! && _saturation != 1) {
          final scaledSaturation =
              (_saturation - 1) * _saturationMultiplier + 1;
          adjustedImage = img.adjustColor(
            adjustedImage,
            saturation:
                scaledSaturation.clamp(0.0, 2.0), // Limit saturation range
          );
        }

        // Apply filter with proper scaling
        if (_appliedAdjustments['filter']! && _selectedFilter != 'None') {
          final filterValues = filters[_selectedFilter]!;
          adjustedImage = img.colorOffset(
            adjustedImage,
            red: ((filterValues[0] - 1) * 64).round(), // Reduced intensity
            green: ((filterValues[1] - 1) * 64).round(), // Reduced intensity
            blue: ((filterValues[2] - 1) * 64).round(), // Reduced intensity
          );
        }

        // Optimize output quality
        final adjustedBytes = Uint8List.fromList(
          img.encodeJpg(
            adjustedImage,
            quality: 85, // Slightly reduced quality for better performance
          ),
        );

        if (mounted) {
          setState(() {
            _workingImageBytes = adjustedBytes;
            _imageBytes = adjustedBytes;
          });
        }
      } catch (e) {
        debugPrint('Error applying adjustments: $e');
        // Restore last valid state
        setState(() {
          _workingImageBytes = _croppedImageBytes ?? _originalImageBytes;
          _imageBytes = _croppedImageBytes ?? _originalImageBytes;
        });
        _showError('Error applying adjustments');
      } finally {
        if (mounted) {
          setState(() => _isFilterProcessing = false);
        }
      }
    });
  }

  Future<void> _applyFilter(String filterName) async {
    if (_isFilterProcessing) return;

    try {
      setState(() => _isFilterProcessing = true);

      // Always start from original or cropped image without filters
      final sourceBytes =
          _isCropped ? _originalImageBytes! : _originalImageBytes!;
      final processedBytes = await _applyFilterToImage(sourceBytes, filterName);

      if (mounted) {
        setState(() {
          _selectedFilter = filterName;
          _activeFilter = filterName;
          _workingImageBytes = processedBytes;
          _imageBytes = processedBytes;
          _appliedAdjustments['filter'] = filterName != 'None';
        });
      }
    } catch (e) {
      debugPrint('Error applying filter: $e');
      _showError('Error applying filter');
    } finally {
      if (mounted) {
        setState(() => _isFilterProcessing = false);
      }
    }
  }

  Future<Uint8List> _applyFilterToImage(
      Uint8List imageData, String filterName) async {
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception('Failed to decode image');

    var filteredImage = image.clone();
    final filterValues = filters[filterName]!;

    filteredImage = img.colorOffset(
      filteredImage,
      red: ((filterValues[0] - 1) * 64).round(),
      green: ((filterValues[1] - 1) * 64).round(),
      blue: ((filterValues[2] - 1) * 64).round(),
    );

    return Uint8List.fromList(img.encodeJpg(filteredImage, quality: 90));
  }

  Future<void> _saveFinalImage() async {
    try {
      setState(() => _isSaving = true);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/final_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Use the most recent processed image
      final finalImageBytes =
          _workingImageBytes ?? _imageBytes ?? _originalImageBytes;
      if (finalImageBytes == null) {
        throw Exception('No image data available');
      }

      await tempFile.writeAsBytes(finalImageBytes);
      widget.onImageCropped(tempFile);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error saving image: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return;

    setState(() {
      // Ensure filter is maintained when switching tabs
      _imageBytes = _workingImageBytes ?? _currentImage.value;
      _currentImage.value = _workingImageBytes ?? _imageBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          if (!_isSaving && !_isFilterProcessing) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetAdjustments,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                if (_tabController.index == 0) {
                  _cropController.crop();
                } else {
                  _saveFinalImage();
                }
              },
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // Ensure image is updated when switching tabs
            setState(() {
              _imageBytes = _currentImage.value;
            });
          },
          tabs: const [
            Tab(text: 'Crop'),
            Tab(text: 'Adjust'),
            Tab(text: 'Filters'),
          ],
        ),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Uint8List?>(
              valueListenable: _currentImage,
              builder: (context, imageData, child) {
                if (imageData == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCropTab(),
                    _buildAdjustTab(),
                    _buildFiltersTab(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCropTab() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Crop(
                image: _imageBytes!,
                controller: _cropController,
                aspectRatio: _aspectRatio,
                onCropped: _handleCrop,
                maskColor: Colors.black.withOpacity(0.6),
                baseColor: Colors.black,
                cornerDotBuilder: (size, edgeAlignment) =>
                    const DotControl(color: Colors.white),
                interactive: !_isRotating,
                withCircleUi: _isCircularCrop,
              ),

              // Crop controls overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    _buildCropControls(),
                    if (_aspectRatio != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Aspect Ratio: ${_aspectRatio!.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              // Loading overlay
              if (_cropStatus == CropImageStatus.cropping)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
        _buildAspectRatioSelector(),
      ],
    );
  }

  void _checkCropValidity(Rect cropRect) {
    final minSize = 50.0; // Minimum crop size in pixels

    setState(() {
      _isCropValid = cropRect.width >= minSize && cropRect.height >= minSize;
    });
  }

  void _handleCropChange() {
    setState(() {
      _isCropValid = true;
      _cropStatus = CropImageStatus.ready;
    });
  }

  Widget _buildCropControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _isCircularCrop ? Icons.crop_square : Icons.crop_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isCircularCrop = !_isCircularCrop;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _rotation = (_rotation - 90) % 360;
                _imageBytes = _rotateImage(_imageBytes!, -90);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            onPressed: () {
              setState(() {
                _rotation = (_rotation + 90) % 360;
                _imageBytes = _rotateImage(_imageBytes!, 90);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.aspect_ratio, color: Colors.white),
            onPressed: () {
              setState(() {
                _aspectRatio = _aspectRatio == null ? 1.0 : null;
              });
            },
          ),
        ],
      ),
    );
  }

  Uint8List _rotateImage(Uint8List imageBytes, int angle) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    final rotated = img.copyRotate(image, angle: angle);
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
  }

  Widget _buildAdjustTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: _isFilterProcessing
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    child: Image.memory(
                      _workingImageBytes ?? _originalImageBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          _buildSlider(
            label: 'Brightness',
            icon: Icons.brightness_6,
            min: -100,
            max: 100,
            value: _brightness,
            divisions: 50, // Reduced divisions for smoother performance
            adjustmentType: 'brightness',
            onChanged: (value) {
              setState(() {
                _brightness = value;
              });
              _applyImageAdjustments(_imageBytes!);
            },
          ),
          _buildSlider(
            label: 'Contrast',
            icon: Icons.contrast,
            min: 0.5,
            max: 1.5,
            divisions: 20, // Reduced divisions for smoother performance
            value: _contrast,
            adjustmentType: 'contrast',
            onChanged: (value) {
              setState(() {
                _contrast = value;
              });
              _applyImageAdjustments(_imageBytes!);
            },
          ),
          _buildSlider(
            label: 'Saturation',
            icon: Icons.color_lens,
            min: 0,
            max: 2,
            divisions: 20, // Reduced divisions for smoother performance
            value: _saturation,
            adjustmentType: 'saturation',
            onChanged: (value) {
              setState(() {
                _saturation = value;
              });
              _applyImageAdjustments(_imageBytes!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab() {
    return Column(
      children: [
        Expanded(
          child: _isFilterProcessing
              ? const Center(child: CircularProgressIndicator())
              : InteractiveViewer(
                  child: Image.memory(
                    _workingImageBytes ?? _imageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
        ),
        Container(
          height: 140, // Increased height to accommodate content
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filterName = filters.keys.elementAt(index);
              final isSelected = _selectedFilter == filterName;
              final isActive = _activeFilter == filterName;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () => _applyFilter(filterName),
                  child: SizedBox(
                    // Added fixed size container
                    width: 80, // Fixed width
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // Added to prevent expansion
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            fit: StackFit
                                .expand, // Added to ensure proper fitting
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.matrix([
                                    filters[filterName]![0],
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    filters[filterName]![1],
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    filters[filterName]![2],
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                                  child: Image.memory(
                                    _originalImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8), // Increased spacing
                        Text(
                          filterName,
                          style: TextStyle(
                            fontSize: 12, // Reduced font size
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          maxLines: 1, // Limit to one line
                          overflow:
                              TextOverflow.ellipsis, // Handle overflow text
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
    required String adjustmentType,
    double divisions = 100, // Add divisions parameter
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
            IconButton(
              icon: Icon(
                _appliedAdjustments[adjustmentType]!
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: _appliedAdjustments[adjustmentType]!
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _appliedAdjustments[adjustmentType] =
                      !_appliedAdjustments[adjustmentType]!;
                });
                _applyImageAdjustments(_imageBytes!);
              },
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions.toInt(), // Add stepped values
          onChanged: (newValue) {
            onChanged(newValue);
            _appliedAdjustments[adjustmentType] = true;
          },
        ),
      ],
    );
  }

  Widget _buildAspectRatioSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _buildAspectRatioButton('Free', null),
          _buildAspectRatioButton('1:1', 1.0),
          _buildAspectRatioButton('4:3', 4 / 3),
          _buildAspectRatioButton('16:9', 16 / 9),
        ],
      ),
    );
  }

  Widget _buildAspectRatioButton(String text, double? ratio) {
    final isSelected = _aspectRatio == ratio;
    return FilterChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _aspectRatio = selected ? ratio : null;
        });
      },
    );
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _selectedFilter = 'None';
      _activeFilter = null; // Reset active filter
      _workingImageBytes =
          _isCropped ? _croppedImageBytes : _originalImageBytes;
      _imageBytes = _isCropped ? _croppedImageBytes : _originalImageBytes;
      _appliedAdjustments = {
        'brightness': false,
        'contrast': false,
        'saturation': false,
        'filter': false,
      };
    });
  }
}
