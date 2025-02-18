import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menu_discount.dart';
import 'package:kantin/widgets/menu/addon_editor.dart';
import 'package:kantin/widgets/menu/addon_manager.dart';
import 'package:kantin/widgets/menu/menu_image_gallery.dart';
import 'package:reorderables/reorderables.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/services/database/foodService.dart';
import 'package:kantin/services/database/discountService.dart';
import 'package:kantin/theme/merchant_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/widgets/image_crop_screen.dart';
import 'package:kantin/widgets/addon_dialog.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:kantin/utils/debouncer.dart';

class MenuDetailsScreen extends StatefulWidget {
  final Menu menu;
  final List<FoodAddon> addons;

  const MenuDetailsScreen(
      {super.key, required this.menu, required this.addons});

  @override
  State<MenuDetailsScreen> createState() => _MenuDetailsScreenState();
}

class _MenuDetailsScreenState extends State<MenuDetailsScreen> {
  // Add scroll controller
  final ScrollController _scrollController = ScrollController();
  
  final FoodService _foodService = FoodService();
  final DiscountService _discountService = DiscountService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late Menu _currentMenu;
  List<FoodAddon> _addons = [];
  final bool _isEditingAddons = false;
  List<Discount> _discounts = [];
  List<String> _imagePaths = [];
  List<MenuDiscount> _menuDiscounts = [];
  final _supabase = Supabase.instance.client;

  // Add these properties for price calculations
  double _basePrice = 0;
  double _addonTotal = 0;
  double _finalPrice = 0;
  double _discountAmount = 0; // Add this

  // Add these properties
  bool _hasUnsavedChanges = false;
  String? _errorMessage;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  // Add new properties
  bool _isSaving = false;
  Timer? _saveDebouncer;
  bool _hasChanges = false;

  // Add these properties
  final _debouncer = Debouncer(milliseconds: 500);
  final _menuSubject = BehaviorSubject<Menu>();
  final _addonsSubject = BehaviorSubject<List<FoodAddon>>();
  final _discountsSubject = BehaviorSubject<List<Discount>>();
  bool _needsSync = false;

  // Add this method to track form changes
  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    
    // Debounce auto-save
    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 2), () {
      if (_formKey.currentState?.validate() ?? false) {
        _autoSave();
      }
    });

    // Debounce changes before updating streams
    _debouncer.run(() {
      _menuSubject.add(_currentMenu);
      _addonsSubject.add(_addons);
    });
  }

  @override
  void initState() {
    super.initState();
    _currentMenu = widget.menu;
    _addons = List.from(widget.addons);
    _loadDiscounts();
    _loadMenuDiscounts();
    _initializeImages();
    _calculatePrices(); // Add this

    // Initialize streams
    _menuSubject.add(_currentMenu);
    _addonsSubject.add(_addons);
    
    // Setup stream subscriptions
    _setupStreams();
    
    // Load initial data
    _initializeData();
  }

  void _setupStreams() {
    // Menu changes stream
    _menuSubject
        .debounceTime(const Duration(milliseconds: 500))
        .distinct()
        .listen((menu) {
      if (_needsSync) {
        _syncMenu(menu);
      }
    });

    // Addons changes stream
    _addonsSubject
        .debounceTime(const Duration(milliseconds: 500))
        .distinct()
        .listen((addons) {
      if (_needsSync) {
        _syncAddons(addons);
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      setState(() => _isLoading = true);

      // Create explicit Future list to fix type inference
      final List<Future<void>> futures = [
        _loadDiscounts(),
        _loadMenuDiscounts(),
      ];

      // Initialize images synchronously since it doesn't return a Future
      _initializeImages();

      // Wait for all async operations
      await Future.wait(futures);

      _calculatePrices();
      
      // Enable sync after initial load
      _needsSync = true;
    } catch (e) {
      _showError('Failed to load data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncMenu(Menu menu) async {
    try {
      await _foodService.updateMenu(menu);
      _showSuccess('Menu synchronized');
    } catch (e) {
      _showError('Failed to sync menu: $e');
    }
  }

  Future<void> _syncAddons(List<FoodAddon> addons) async {
    try {
      await Future.wait(
        addons.map((addon) => _foodService.updateFoodAddon(addon)),
      );
      _showSuccess('Add-ons synchronized');
    } catch (e) {
      _showError('Failed to sync add-ons: $e');
    }
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    _scrollController.dispose(); // Dispose the controller

    // Clean up streams
    _menuSubject.close();
    _addonsSubject.close();
    _discountsSubject.close();
    _debouncer.dispose();
    
    super.dispose();
  }

  // Override willPop to show unsaved changes dialog
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _initializeImages() {
    if (_currentMenu.photo != null && _currentMenu.photo!.isNotEmpty) {
      // Don't reconstruct the URL if it's already a full URL
      final imageUrl = _currentMenu.photo!.startsWith('http')
          ? _currentMenu.photo!
          : _supabase.storage
              .from(
                  'menu_images') // Make sure this matches your bucket name exactly
              .getPublicUrl(_currentMenu.photo!);

      setState(() {
        _imagePaths = [imageUrl];
      });

      print('Initialized image URL: $imageUrl'); // Debug print
    }
  }

  // Improve error handling
  void _showError(String message, {bool persistent = false}) {
    setState(() => _errorMessage = message);
    
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          _scaffoldKey.currentState?.hideCurrentSnackBar();
          setState(() => _errorMessage = null);
        },
      ),
      duration: persistent ? const Duration(days: 1) : const Duration(seconds: 4),
    );

    _scaffoldKey.currentState?.showSnackBar(snackBar);
  }

  void _showSuccess(String message) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          Text(message),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    );

    _scaffoldKey.currentState?.showSnackBar(snackBar);
  }

  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _isSaving) return;
    
    try {
      _formKey.currentState?.save();
      await _foodService.updateMenu(_currentMenu);
      setState(() => _hasUnsavedChanges = false);
      _showSuccess('Changes auto-saved');
    } catch (e) {
      _showError('Auto-save failed: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fix the errors before saving');
      return;
    }
    
    try {
      setState(() => _isSaving = true);
      
      if (_currentMenu.id == null) {
        throw Exception('Menu ID is required');
      }
      
      _formKey.currentState!.save();
      
      // Update streams with latest data
      _menuSubject.add(_currentMenu);
      _addonsSubject.add(_addons);
      
      // Wait for all pending syncs
      await Future.wait([
        _syncMenu(_currentMenu),
        _syncAddons(_addons),
      ]);
      
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      
      _showSuccess('Changes saved successfully');
      
      // Vibrate for feedback
      HapticFeedback.mediumImpact();
      
      // Return to previous screen
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Failed to save changes: $e');
    }
  }

  void _reorderAddons(List<FoodAddon> newAddons) {
    setState(() {
      _addons = newAddons;
    });
  }

  void _editAddon(FoodAddon addon) {
    // Implement edit addon logic
  }

  void _removeAddon(FoodAddon addon) {
    // Implement delete addon logic
  }

  Future<void> _loadDiscounts() async {
    try {
      final discounts = await _discountService.getDiscounts();
      setState(() {
        _discounts = discounts;
      });
    } catch (e) {
      _showError('Failed to load discounts: $e');
    }
  }

  Future<void> _loadMenuDiscounts() async {
    try {
      final menuDiscounts = await _discountService.getMenuDiscounts(_currentMenu.id!);
      final discounts = await _discountService.getDiscounts();
      
      setState(() {
        _menuDiscounts = menuDiscounts;
        _discounts = discounts.map((discount) {
          // Check if this discount is applied to this menu
          final isApplied = menuDiscounts.any((md) => md.discountId == discount.id);
          if (isApplied) {
            // Update discount status based on global discount status
            return discount.copyWith(
              isActive: discount.isActive && isApplied
            );
          }
          return discount;
        }).toList();
        
        // Recalculate prices after loading discounts
        _calculatePrices();
      });
    } catch (e) {
      _showError('Failed to load menu discounts: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // Upload to Supabase storage
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final bytes = await image.readAsBytes();

        // Upload the file
        await _supabase.storage
            .from(
                'menu_images') // Make sure this matches your bucket name exactly
            .uploadBinary(fileName, bytes);

        // Get the public URL
        final imageUrl =
            _supabase.storage.from('menu_images').getPublicUrl(fileName);

        // Update menu with new image path (just the filename)
        _currentMenu = _currentMenu.copyWith(photo: fileName);
        await _foodService.updateMenu(_currentMenu);

        setState(() {
          _imagePaths = [imageUrl];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to pick/upload image: $e');
    }
  }

  void _removeImage(int index) => setState(() => _imagePaths.removeAt(index));

  Future<void> _toggleDiscount(Discount discount) async {
    try {
      final currentPosition = _scrollController.offset;
      setState(() => _isLoading = true);

      // First update the global discount status
      await _discountService.toggleDiscountStatus(discount.id, !discount.isActive);

      // Then update menu-specific discount
      if (_currentMenu.id != null) {
        await _discountService.updateMenuDiscount(
          _currentMenu.id!,
          discount.id,
          !discount.isActive,
        );
      }

      // Reload all discounts to get the synchronized state
      await _loadMenuDiscounts();

      setState(() {
        discount.isActive = !discount.isActive;
        _errorMessage = null;
      });

      // Recalculate prices immediately after discount status change
      _calculatePrices();

      _showSuccess(discount.isActive ? 'Discount activated' : 'Discount deactivated');

      // Restore scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(currentPosition);
        }
      });
    } catch (e) {
      _showError('Failed to toggle discount: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculatePrices() {
    _basePrice = _currentMenu.price;
    _addonTotal = _addons.where((addon) => addon.isRequired).fold(
      0,
      (sum, addon) => sum + addon.price,
    );

    // Update discount calculation to consider global discount status
    _discountAmount = _menuDiscounts.fold(0, (sum, menuDiscount) {
      final discount = _discounts.firstWhere(
        (d) => d.id == menuDiscount.discountId,
        orElse: () => Discount(
          id: -1,
          discountName: '',
          discountPercentage: 0,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
          isActive: false,
          stallId: -1,
        ),
      );
      
      // Only apply discount if both global and menu-specific status are active
      return discount.id != -1 && discount.isActive 
          ? sum + (_basePrice * discount.discountPercentage / 100) 
          : sum;
    });

    _finalPrice = _basePrice + _addonTotal - _discountAmount;
    setState(() {});
  }

  Future<void> _showAddonDialog(FoodAddon? addon) async {
    try {
      final addonData = await showDialog<FoodAddon?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Theme(
          data: Theme.of(context).copyWith(
            // Ensure consistent dialog styling
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            // Use the same color scheme
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFF542D), // Your app's primary color
            ),
          ),
          child: Material( // Add this Material widget
            type: MaterialType.transparency,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: AddonDialog(
                key: ValueKey(addon?.id ?? 'new'),
                addon: addon,
                menuId: _currentMenu.id!,
              ),
            ),
          ),
        ),
      );

      if (addonData != null && mounted) {
        setState(() => _isLoading = true);

        try {
          if (addon == null) {
            // Creating new addon
            await _foodService.createFoodAddon(addonData);
          } else {
            // Updating existing addon
            await _foodService.updateFoodAddon(addonData);
          }

          // Refresh the addons list
          final updatedAddons = await _foodService.getAddonsForMenu(_currentMenu.id!);
          setState(() {
            _addons = updatedAddons;
            _calculatePrices(); // Recalculate prices after addon changes
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addon == null ? 'Add-on created successfully' : 'Add-on updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          _showError('Failed to save add-on: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Theme(
          data: MerchantTheme.lightTheme(),
          child: Scaffold(
            appBar: AppBar(
              title: Text(_currentMenu.foodName),
              actions: [
                if (_hasUnsavedChanges)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Unsaved',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: _showQRCode,
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate Menu'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete Menu', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'duplicate') _duplicateMenu();
                    if (value == 'delete') _confirmDelete();
                  },
                ),
              ],
            ),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MenuImageGallery(
                            images: _imagePaths,
                            onImagePicked: _handleImagePicked,
                            onImageRemoved: _removeImage,
                            isLoading: _isLoading,
                          ),
                          if (_hasUnsavedChanges && MediaQuery.of(context).size.width >= 600)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Card(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Text('You have unsaved changes'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _formKey.currentState?.reset();
                                          setState(() => _hasUnsavedChanges = false);
                                        },
                                        child: const Text('Discard'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Form(
                            key: _formKey,
                            onChanged: _onFormChanged,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBasicInfoSection(),
                                const Divider(height: 32),
                                _buildPriceBreakdown(),
                                _buildPricingSection(),
                                const Divider(height: 32),
                                _buildAddonsSection(),
                                const Divider(height: 32),
                                _buildDiscountSection(),
                                const Divider(height: 32),
                                _buildAvailabilitySection(),
                                // Add bottom padding to account for the bottom bar
                                SizedBox(height: _hasUnsavedChanges ? 80 : 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_hasUnsavedChanges) ...[
                    Expanded(
                      child: Text(
                        'You have unsaved changes',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _formKey.currentState?.reset();
                        setState(() => _hasUnsavedChanges = false);
                      },
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: _hasUnsavedChanges ? 0 : 1,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSaving)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(Icons.save),
                          const SizedBox(width: 8),
                          Text(_isSaving ? 'Saving...' : 'Save Changes'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Remove the floating action button since we have a consistent bottom bar now
            floatingActionButton: null,
          ),
        ),
      ),
    );
  }

  Future<void> _handleImagePicked(XFile image) async {
    if (!mounted) return;

    try {
      // Show loading indicator
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Upload the cropped image
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final bytes = await image.readAsBytes();

      await _supabase.storage.from('menu_images').uploadBinary(fileName, bytes);

      final imageUrl =
          _supabase.storage.from('menu_images').getPublicUrl(fileName);

      // Update state only if widget is still mounted
      if (mounted) {
        setState(() {
          _imagePaths.add(imageUrl);
          _currentMenu = _currentMenu.copyWith(photo: fileName);
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to upload image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLoadingScreen() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image with parallax effect
            if (_imagePaths.isNotEmpty)
              Hero(
                tag: 'menu-${widget.menu.id}',
                child: PageView.builder(
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      return _buildAddImageButton();
                    }
                    return _buildImageViewerWithOverlay(index);
                  },
                ),
              )
            else
              _buildNoImagePlaceholder(),
            // Gradient overlay
            _buildGradientOverlay(),
            // Bottom info
            _buildImageBottomInfo(),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code, color: Colors.white),
          onPressed: _showQRCode,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showMoreOptions,
        ),
      ],
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentMenu.type == 'food'
                  ? Icons.restaurant
                  : Icons.local_drink,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No image available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.add_a_photo, size: 50),
        ),
      ),
    );
  }

  Widget _buildImageViewerWithOverlay(int index) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CachedNetworkImage(
            imageUrl: _imagePaths[index],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(color: Colors.white),
            ),
            errorWidget: (context, url, error) {
              print('Error loading image: $error'); // Debug print
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red[300], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading image\n$error',
                      style: TextStyle(color: Colors.red[300]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.delete),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _removeImage(index),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.5), Colors.transparent],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _buildImageBottomInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentMenu.foodName,
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${_currentMenu.price.toStringAsFixed(0)}',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            'Today\'s Sales',
            '15',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Rating',
            '4.8',
            Icons.star,
            Colors.amber,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            'Review',
            '120',
            Icons.message,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const Divider(),
            _buildPricingSection(),
            const Divider(),
            _buildAddonsSection(),
            const Divider(),
            _buildDiscountSection(),
            const Divider(),
            _buildAvailabilitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentMenu.foodName,
            decoration: const InputDecoration(
              labelText: 'Menu Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant_menu),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Name is required' : null,
            onSaved: (value) {
              if (value != null) {
                _currentMenu = _currentMenu.copyWith(foodName: value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentMenu.description,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            onSaved: (value) {
              if (value != null) {
                _currentMenu = _currentMenu.copyWith(description: value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _currentMenu.type,
            decoration: const InputDecoration(
              labelText: 'Menu Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: ['food', 'drink']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.toUpperCase()),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentMenu = _currentMenu.copyWith(type: value);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentMenu.price.toString(),
            decoration: const InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Price is required';
              }
              if (double.tryParse(value) == null) {
                return 'Invalid price';
              }
              return null;
            },
            onSaved: (value) {
              if (value != null) {
                _currentMenu =
                    _currentMenu.copyWith(price: double.parse(value));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddonsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add-ons',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddonDialog(null), // Fixed
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_addons.isEmpty)
            Center(
              child: Text(
                'No add-ons yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addons.length,
              itemBuilder: (context, index) {
                final addon = _addons[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          addon.addonName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (addon.isRequired)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rp ${addon.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (addon.description?.isNotEmpty ?? false)
                          Text(
                            addon.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddonDialog(addon), // Fixed
                          color: Theme.of(context).primaryColor,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteAddon(addon),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _deleteAddon(FoodAddon addon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Add-on'),
        content: Text('Are you sure you want to delete "${addon.addonName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        setState(() => _isLoading = true);
        await _foodService.deleteFoodAddon(addon.id!);
        
        // Refresh the addons list
        final updatedAddons = await _foodService.getAddonsForMenu(_currentMenu.id!);
        setState(() {
          _addons = updatedAddons;
          _calculatePrices(); // Recalculate prices after deletion
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add-on deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showError('Failed to delete add-on: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildDiscountSection() {
    final appliedDiscounts = _discounts.where((discount) {
      return _menuDiscounts
          .any((menuDiscount) => menuDiscount.discountId == discount.id);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discounts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_discountAmount > 0)
                Chip(
                  label: Text('${(_discountAmount / _basePrice * 100).toStringAsFixed(0)}% OFF'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appliedDiscounts.length,
            itemBuilder: (context, index) {
              final discount = appliedDiscounts[index];
              return Card(
                child: ListTile(
                  title: Row(
                    children: [
                      Text(discount.discountName),
                      const SizedBox(width: 8),
                      if (discount.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${discount.discountPercentage}% off'),
                      Text(
                        'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - ${DateFormat('MMM dd').format(discount.endDate)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Switch.adaptive(
                    value: discount.isActive,
                    onChanged: (value) async {
                      HapticFeedback.selectionClick();
                      await _toggleDiscount(discount);
                    },
                  ),
                ),
              );
            },
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Available'),
            value: _currentMenu.isAvailable ?? true,
            onChanged: (value) {
              setState(() {
                _currentMenu = _currentMenu.copyWith(isAvailable: value);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 300, // Fixed width for the dialog
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important to constrain height
            children: [
              Text(
                'QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200, // Fixed width for QR code
                height: 200, // Fixed height for QR code
                child: QrImageView(
                  data: 'menu:${_currentMenu.id}',
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // Implement QR code sharing
                    },
                    child: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Duplicate Menu'),
            onTap: () {
              Navigator.pop(context);
              _duplicateMenu();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title:
                const Text('Delete Menu', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateMenu() async {
    // Implement duplicate functionality
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu'),
        content: const Text('Are you sure you want to delete this menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implement delete functionality
    }
  }

  // Add this widget to show price breakdown
  Widget _buildPriceBreakdown() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow('Base Price', _basePrice),
            if (_addonTotal > 0) _buildPriceRow('Required Add-ons', _addonTotal),
            if (_discountAmount > 0) _buildPriceRow('Discount', -_discountAmount, style: TextStyle(color: Colors.red)),
            const Divider(height: 24),
            _buildPriceRow(
              'Final Price',
              _finalPrice,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: style,
          ),
        ],
      ),
    );
  }

  // Memory optimization - override didUpdateWidget
  @override
  void didUpdateWidget(MenuDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only update if menu or addons changed
    if (widget.menu != oldWidget.menu) {
      _currentMenu = widget.menu;
      _menuSubject.add(_currentMenu);
    }
    
    if (widget.addons != oldWidget.addons) {
      _addons = List.from(widget.addons);
      _addonsSubject.add(_addons);
    }
  }
}
