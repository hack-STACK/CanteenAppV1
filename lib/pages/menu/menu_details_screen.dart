import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menu_discount.dart';
import 'package:kantin/widgets/menu/menu_image_gallery.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/services/database/foodService.dart';
import 'package:kantin/services/database/discountService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/widgets/addon_dialog.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:kantin/utils/debouncer.dart';

// At the top of your file, add this extension method
extension FoodServiceExtension on FoodService {
  // This is a temporary workaround
  Future<void> updateMenuWithMap(Map<String, dynamic> menuData) async {
    try {
      if (!menuData.containsKey('id')) {
        throw Exception('Menu ID is required for update');
      }

      final menuId = menuData['id'];
      final updateData = Map<String, dynamic>.from(menuData);
      updateData
          .removeWhere((key, value) => ['id', 'is_popular'].contains(key));

      await Supabase.instance.client
          .from('menu')
          .update(updateData)
          .eq('id', menuId);
    } catch (e) {
      print('Error updating menu with map: $e');
      throw Exception('Failed to update menu: $e');
    }
  }
}

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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // Add new properties
  bool _isSaving = false;
  Timer? _saveDebouncer;
  final bool _hasChanges = false;

  // Add these properties
  final _debouncer = Debouncer(milliseconds: 500);
  final _menuSubject = BehaviorSubject<Menu>();
  final _addonsSubject = BehaviorSubject<List<FoodAddon>>();
  final _discountsSubject = BehaviorSubject<List<Discount>>();
  bool _needsSync = false;
  bool _updatingMenu = false;

  // Add new properties for discount handling
  final Map<int, bool> _discountLoadingStates = {};
  final ValueNotifier<Set<int>> _activeDiscountIds = ValueNotifier({});
  final Map<int, String> _discountErrors = {};
  int? _stallId;

  // Add these properties to track subscriptions
  late StreamSubscription _menuSubscription;
  late StreamSubscription _addonsSubscription;

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

    // Wait until data is loaded before enabling sync
    Future.delayed(Duration(seconds: 1), () {
      _needsSync = true;
    });
  }

  void _setupStreams() {
    // Menu changes stream
    _menuSubscription = _menuSubject
        .debounceTime(const Duration(milliseconds: 1000))
        .distinct()
        .listen(
      (menu) {
        if (_needsSync && mounted && !_updatingMenu) {
          _syncMenu(menu);
        }
      },
      onError: (e) {
        print('Error in menu stream: $e');
        if (mounted) {
          _showError('Sync error: $e');
        }
      },
    );

    // Addons changes stream
    _addonsSubscription = _addonsSubject
        .debounceTime(const Duration(milliseconds: 1000))
        .distinct()
        .listen(
      (addons) {
        if (_needsSync && mounted) {
          _syncAddons(addons);
        }
      },
      onError: (e) {
        print('Error in addons stream: $e');
        if (mounted) {
          _showError('Sync error: $e');
        }
      },
    );
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
    if (!mounted || _updatingMenu) return;

    try {
      setState(() => _updatingMenu = true);

      // Log before update for debugging
      print('Syncing menu: ${menu.id} - ${menu.foodName} - ${menu.price}');

      // Create a map of the menu properties and explicitly remove isPopular
      final Map<String, dynamic> menuData = {
        'id': menu.id,
        'food_name': menu.foodName,
        'description': menu.description,
        'price': menu.price,
        'stall_id': menu.stallId,
        'photo': menu.photo,
        'is_available': menu.isAvailable,
        'type': menu.type,
        // Explicitly exclude isPopular field
      };

      // Make sure to await the update
      await _foodService.updateMenuWithMap(menuData);

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _updatingMenu = false;
        });
        _showSuccess('Menu updated');
      }
    } catch (e) {
      print('Menu sync error: $e');
      if (mounted) {
        setState(() => _updatingMenu = false);
        _showError('Failed to sync menu: $e');
      }
    }
  }

  Future<void> _syncAddons(List<FoodAddon> addons) async {
    if (!mounted) return; // Early return if not mounted

    try {
      await Future.wait(
        addons.map((addon) => _foodService.updateFoodAddon(addon)),
      );
      if (mounted) {
        // Check mounted before showing success
        _showSuccess('Add-ons synchronized');
      }
    } catch (e) {
      if (mounted) {
        // Check mounted before showing error
        _showError('Failed to sync add-ons: $e');
      }
    }
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    _scrollController.dispose(); // Dispose the controller

    // Cancel stream subscriptions
    _menuSubscription.cancel();
    _addonsSubscription.cancel();

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
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave?'),
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
    if (!mounted) return; // Early return if not mounted

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
      duration:
          persistent ? const Duration(days: 1) : const Duration(seconds: 4),
    );

    _scaffoldKey.currentState?.showSnackBar(snackBar);
  }

  void _showSuccess(String message) {
    if (!mounted) return; // Early return if not mounted

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
      setState(() => _isSaving = true);

      // Save form values to menu object
      _formKey.currentState?.save();

      // Trigger sync through subject
      _menuSubject.add(_currentMenu);

      // Wait a moment before showing success
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccess('Changes auto-saved');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Auto-save failed: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fix the errors before saving');
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Log values before saving
      print(
          'Before save - Type: ${_currentMenu.type}, Price: ${_currentMenu.price}');

      // Save form values to current menu object
      _formKey.currentState!.save();

      // Log values after saving
      print(
          'After save - Type: ${_currentMenu.type}, Price: ${_currentMenu.price}');

      // Create a clean map of the menu properties without isPopular
      final Map<String, dynamic> menuData = {
        'id': _currentMenu.id,
        'food_name': _currentMenu.foodName,
        'description': _currentMenu.description,
        'price': _currentMenu.price,
        'stall_id': _currentMenu.stallId,
        'photo': _currentMenu.photo,
        'is_available': _currentMenu.isAvailable,
        'type': _currentMenu.type,
        // Exclude isPopular field
      };

      // Log the actual data being sent
      print('Updating menu with data: $menuData');

      // Use your extension method instead of updateMenu
      await _foodService.updateMenuWithMap(menuData);

      // Also sync addons if needed
      if (_addons.isNotEmpty) {
        await Future.wait(
            _addons.map((addon) => _foodService.updateFoodAddon(addon)));
      }

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
          _isSaving = false;
        });
        _showSuccess('Changes saved successfully');
      }

      // Vibrate for feedback
      HapticFeedback.mediumImpact();

      // Return to previous screen
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Failed to save changes: $e');
      }
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
      final discounts = await _discountService.getDiscountsByStallId(_stallId!);
      if (!mounted) {
        return; // Ensure the widget is still mounted before updating state
      }

      setState(() {
        _discounts = discounts;
      });
    } catch (e) {
      _showError('Failed to load discounts: $e');
    }
  }

  // Update loadMenuDiscounts with better error handling
  Future<void> _loadMenuDiscounts() async {
    try {
      final menuDiscounts =
          await _discountService.getMenuDiscountsByMenuId(_currentMenu.id);

      // Set stallId from menu instead of menuDiscounts
      _stallId =
          _currentMenu.stallId; // Make sure Menu model has stallId property

      if (!mounted) return;

      setState(() {
        _menuDiscounts = menuDiscounts;
        // Only get discounts from menuDiscounts if there are any
        _discounts = menuDiscounts.isNotEmpty
            ? menuDiscounts
                .map((md) => md.discount)
                .whereType<Discount>()
                .toList()
            : [];

        // Update active discount IDs
        _activeDiscountIds.value = menuDiscounts
            .where((md) => md.isActive)
            .map((md) => md.discountId)
            .toSet();

        _calculatePrices();
      });
    } catch (e) {
      debugPrint('Error loading menu discounts: $e');
      if (mounted) {
        _showError('Failed to load discounts: $e');
      }
    }
  }

  // Replace existing _toggleDiscount with this improved version
  Future<void> _toggleDiscount(Discount discount) async {
    if (_discountLoadingStates[discount.id] == true) return;

    try {
      setState(() => _discountLoadingStates[discount.id] = true);

      // First validate if discount can be applied
      if (_stallId != null) {
        final isValid = await _discountService.validateDiscountFromMenu(
            discount.id, _currentMenu.id, _stallId!);

        if (!isValid) {
          throw Exception('This discount cannot be applied to this menu');
        }
      }

      // Find existing menu discount
      final existingMenuDiscount = _menuDiscounts.firstWhere(
        (md) => md.discountId == discount.id,
        orElse: () => MenuDiscount(
          id: 0,
          menuId: _currentMenu.id,
          discountId: discount.id,
          isActive: false,
          discount: discount,
        ),
      );

      final newStatus = !existingMenuDiscount.isActive;

      if (newStatus) {
        // Check for overlapping discounts
        if (!_canApplyDiscount(discount)) {
          throw Exception(
              'This discount cannot be combined with existing discounts');
        }
      }

      await _discountService.updateMenuDiscount(
        _currentMenu.id,
        discount.id,
        newStatus,
      );

      if (!mounted) return;

      setState(() {
        _discountErrors.remove(discount.id);

        final index =
            _menuDiscounts.indexWhere((md) => md.discountId == discount.id);
        if (index != -1) {
          _menuDiscounts[index] =
              existingMenuDiscount.copyWith(isActive: newStatus);
        } else {
          _menuDiscounts.add(existingMenuDiscount.copyWith(isActive: true));
        }

        // Update active discount IDs
        if (newStatus) {
          _activeDiscountIds.value.add(discount.id);
        } else {
          _activeDiscountIds.value.remove(discount.id);
        }

        _calculatePrices();
      });

      _showSuccess(newStatus ? 'Discount applied' : 'Discount removed');
    } catch (e) {
      setState(() {
        _discountErrors[discount.id] = e.toString();
      });
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _discountLoadingStates[discount.id] = false);
      }
    }
  }

  // Add method to detach discount
  Future<void> _detachDiscount(Discount discount) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Detach Discount'),
          content: const Text(
              'Remove this discount from the menu? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Detach'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _discountLoadingStates[discount.id] = true);

      await _discountService.detachMenuDiscount(_currentMenu.id, discount.id);

      if (!mounted) return;

      setState(() {
        // Remove the discount from _menuDiscounts
        _menuDiscounts.removeWhere((md) => md.discountId == discount.id);
        // Remove from active discounts
        _activeDiscountIds.value.remove(discount.id);
        // Remove from discounts list
        _discounts.removeWhere((d) => d.id == discount.id);
        // Recalculate prices
        _calculatePrices();
      });

      _showSuccess('Discount detached from menu');
    } catch (e) {
      _showError('Failed to detach discount: $e');
    } finally {
      if (mounted) {
        setState(() => _discountLoadingStates[discount.id] = false);
      }
    }
  }

  // Add helper method to validate discount combinations
  bool _canApplyDiscount(Discount newDiscount) {
    // Get currently active discounts
    final activeDiscounts = _menuDiscounts
        .where((md) => md.isActive)
        .map((md) => md.discount)
        .whereType<Discount>()
        .toList();

    // Check for overlapping dates
    for (final active in activeDiscounts) {
      if (active.id == newDiscount.id) continue;

      final overlaps = newDiscount.startDate.isBefore(active.endDate) &&
          active.startDate.isBefore(newDiscount.endDate);

      if (overlaps) {
        return false;
      }
    }

    return true;
  }

  void _calculatePrices() {
    _basePrice = _currentMenu.price;
    _addonTotal = _addons.where((addon) => addon.isRequired).fold(
          0,
          (sum, addon) => sum + addon.price,
        );

    // Calculate discount based on active menu discounts only
    _discountAmount =
        _menuDiscounts.where((md) => md.isActive).fold(0, (sum, menuDiscount) {
      final discount = menuDiscount.discount;

      if (discount != null &&
          discount.startDate.isBefore(DateTime.now()) &&
          discount.endDate.isAfter(DateTime.now())) {
        return sum + (_basePrice * discount.discountPercentage / 100);
      }
      return sum;
    });

    _finalPrice = _basePrice + _addonTotal - _discountAmount;
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
          child: Material(
            // Add this Material widget
            type: MaterialType.transparency,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: AddonDialog(
                key: ValueKey(addon?.id ?? 'new'),
                addon: addon,
                menuId: _currentMenu.id,
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
          final updatedAddons =
              await _foodService.getAddonsForMenu(_currentMenu.id);
          setState(() {
            _addons = updatedAddons;
            _calculatePrices(); // Recalculate prices after addon changes
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(addon == null
                  ? 'Add-on created successfully'
                  : 'Add-on updated successfully'),
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

  // 6. Improve the bottom bar UI
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_currentMenu.foodName,
                style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            actions: [
              if (_hasUnsavedChanges)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Unsaved',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.qr_code),
                tooltip: 'Show QR Code',
                onPressed: _showQRCode,
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert),
                tooltip: 'More options',
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 18),
                        SizedBox(width: 8),
                        Text('Duplicate Menu'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Menu',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'duplicate') _duplicateMenu();
                  if (value == 'delete') _confirmDelete();
                },
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 16),
                      Text('Loading menu details...'),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
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
                        if (_hasUnsavedChanges)
                          Container(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have unsaved changes',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _formKey.currentState?.reset();
                                    setState(() => _hasUnsavedChanges = false);
                                  },
                                  child: Text('DISCARD'),
                                ),
                              ],
                            ),
                          ),
                        Form(
                          key: _formKey,
                          onChanged: _onFormChanged,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBasicInfoSection(),
                              const Divider(height: 32, thickness: 1),
                              _buildPriceBreakdown(),
                              _buildPricingSection(),
                              const Divider(height: 32, thickness: 1),
                              _buildAddonsSection(),
                              const Divider(height: 32, thickness: 1),
                              _buildAvailabilitySection(),
                              SizedBox(
                                  height: 100), // Extra space for bottom bar
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: Material(
            elevation: 8,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_hasUnsavedChanges) ...[
                    Expanded(
                      child: Text(
                        'Save changes to publish this menu item',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  SizedBox(
                    width: _hasUnsavedChanges ? 150 : 200,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            Icon(Icons.save_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(_isSaving ? 'SAVING...' : 'SAVE MENU'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

      if (!mounted) return;

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
          colors: [
            Colors.black.withAlpha(128), // Replace withOpacity(0.5)
            Colors.transparent
          ],
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

  // 4. Improve the basic info section UI
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
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentMenu.foodName,
            decoration: InputDecoration(
              labelText: 'Menu Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.restaurant_menu),
              helperText: 'Enter a descriptive name for this menu item',
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Name is required' : null,
            onChanged: (value) {
              _updateMenu(_currentMenu.copyWith(foodName: value));
            },
            onSaved: (value) {
              if (value != null) {
                _currentMenu = _currentMenu.copyWith(foodName: value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentMenu.description,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
              helperText: 'Describe the menu item (ingredients, taste, etc.)',
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
            onChanged: (value) {
              _updateMenu(_currentMenu.copyWith(description: value));
            },
            onSaved: (value) {
              if (value != null) {
                _currentMenu = _currentMenu.copyWith(description: value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _currentMenu.type,
            decoration: InputDecoration(
              labelText: 'Menu Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(_currentMenu.type == 'food'
                  ? Icons.restaurant
                  : Icons.local_drink),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: ['food', 'drink']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            type == 'food'
                                ? Icons.restaurant
                                : Icons.local_drink,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text(type.toUpperCase()),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _updateMenu(_currentMenu.copyWith(type: value));
              }
            },
            onSaved: (value) {
              if (value != null) {
                _currentMenu = _currentMenu.copyWith(type: value);
              }
            },
          ),
        ],
      ),
    );
  }

  // 5. Improve the pricing section UI
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
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentMenu.price.toString(),
            decoration: InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: Icon(Icons.payments),
              prefixText: 'Rp ',
              helperText: 'Enter the base price without add-ons',
              filled: true,
              fillColor: Colors.grey[50],
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
            onChanged: (value) {
              final price = double.tryParse(value);
              if (price != null) {
                _updateMenu(_currentMenu.copyWith(price: price));
                _calculatePrices();
              }
            },
            onSaved: (value) {
              if (value != null) {
                final price = double.tryParse(value) ?? _currentMenu.price;
                _currentMenu = _currentMenu.copyWith(price: price);
                _calculatePrices();
              }
            },
          ),
        ],
      ),
    );
  }

  // 2. Enhance the addons section
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddonDialog(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Add-on'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontWeight: FontWeight.w500),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_addons.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No add-ons yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add extras, toppings or customizations',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
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
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Required',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(addon.price),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
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
                          onPressed: () => _showAddonDialog(addon),
                          color: Colors.blue,
                          tooltip: 'Edit add-on',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteAddon(addon),
                          color: Colors.red,
                          tooltip: 'Delete add-on',
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
        final updatedAddons =
            await _foodService.getAddonsForMenu(_currentMenu.id);
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

  // Update the discount section UI
  Widget _buildDiscountSection() {
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
              Row(
                children: [
                  if (_discountAmount > 0)
                    Chip(
                      label: Text(
                          '${(_discountAmount / _basePrice * 100).toStringAsFixed(0)}% OFF'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _showAddDiscountDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Discount'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<Set<int>>(
            valueListenable: _activeDiscountIds,
            builder: (context, activeIds, _) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _discounts.length,
                itemBuilder: (context, index) {
                  final discount = _discounts[index];
                  final isActive = activeIds.contains(discount.id);
                  final isLoading =
                      _discountLoadingStates[discount.id] ?? false;
                  final isValid = _isDiscountValid(discount);

                  return _buildDiscountCard(
                    discount: discount,
                    isActive: isActive,
                    isLoading: isLoading,
                    isValid: isValid,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isDiscountValid(Discount discount) {
    final now = DateTime.now();
    return discount.startDate.isBefore(now) && discount.endDate.isAfter(now);
  }

  Widget _buildDiscountCard({
    required Discount discount,
    required bool isActive,
    required bool isLoading,
    required bool isValid,
  }) {
    final bool isFromOtherMerchant = discount.stallId != _stallId;
    final String? error = _discountErrors[discount.id];

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discount.discountName),
                      if (isFromOtherMerchant)
                        Text(
                          'From different merchant',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isActive && isValid)
                  Chip(
                    label: Text('${discount.discountPercentage}% OFF'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - ${DateFormat('MMM dd').format(discount.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isValid ? null : Colors.red,
                  ),
                ),
                if (error != null)
                  Text(
                    error,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch.adaptive(
                  value: isActive,
                  onChanged: isLoading || !isValid
                      ? null
                      : (value) => _toggleDiscount(discount),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: isLoading ? null : () => _detachDiscount(discount),
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDiscountDialog() async {
    try {
      if (_stallId == null) {
        throw Exception('Stall ID is required');
      }

      final availableDiscounts =
          await _discountService.getDiscountsByStallId(_stallId!);

      if (!mounted) return;

      // Filter out already applied discounts
      final appliedDiscountIds =
          _menuDiscounts.map((md) => md.discountId).toSet();
      final unusedDiscounts = availableDiscounts
          .where((d) => !appliedDiscountIds.contains(d.id))
          .toList();

      if (unusedDiscounts.isEmpty) {
        _showError('No available discounts to add');
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add Discount'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: unusedDiscounts.length,
              itemBuilder: (context, index) {
                final discount = unusedDiscounts[index];
                final isValid = _isDiscountValid(discount);

                return ListTile(
                  enabled: isValid,
                  title: Text(discount.discountName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${discount.discountPercentage}% OFF'),
                      Text(
                        'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - ${DateFormat('MMM dd').format(discount.endDate)}',
                        style: TextStyle(
                          color: isValid ? null : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: isValid
                        ? () async {
                            Navigator.pop(context);
                            await _applyDiscount(discount);
                          }
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showError('Error loading discounts: $e');
    }
  }

  Future<void> _applyDiscount(Discount discount) async {
    try {
      setState(() => _discountLoadingStates[discount.id] = true);

      if (!_canApplyDiscount(discount)) {
        throw Exception('Cannot combine with existing discounts');
      }

      await _discountService.addMenuDiscount(
        MenuDiscount(
          id: 0,
          menuId: _currentMenu.id,
          discountId: discount.id,
          isActive: true,
          discount: discount,
        ),
      );

      // Refresh menu discounts
      await _loadMenuDiscounts();

      _showSuccess('Discount applied successfully');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _discountLoadingStates[discount.id] = false);
      }
    }
  }

  // 3. Improve the availability section
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
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: Text(
                  'Available for Order',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _currentMenu.isAvailable ?? true
                      ? 'This item will be shown to customers'
                      : 'This item will be hidden from customers',
                  style: TextStyle(fontSize: 13),
                ),
                secondary: Icon(
                  _currentMenu.isAvailable ?? true
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: _currentMenu.isAvailable ?? true
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                value: _currentMenu.isAvailable ?? true,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  _updateMenu(_currentMenu.copyWith(isAvailable: value));
                },
              ),
            ),
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

  // 1. First, let's improve the price breakdown section
  Widget _buildPriceBreakdown() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPriceRow('Base Price', _basePrice),
            if (_addonTotal > 0)
              _buildPriceRow('Required Add-ons', _addonTotal),
            if (_discountAmount > 0)
              _buildPriceRow('Discount', -_discountAmount,
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildPriceRow('Final Price', _finalPrice,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {TextStyle? style}) {
    final formattedAmount = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount.abs());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            amount < 0 ? "- $formattedAmount" : formattedAmount,
            style: style ?? TextStyle(fontWeight: FontWeight.w500),
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

  // Add this method to update menu and trigger sync
  void _updateMenu(Menu updatedMenu) {
    setState(() {
      _currentMenu = updatedMenu;
      _hasUnsavedChanges = true;
    });

    // Add to subject to trigger sync
    _menuSubject.add(_currentMenu);
  }
}
