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

class MenuDetailsScreen extends StatefulWidget {
  final Menu menu;
  final List<FoodAddon> addons;

  const MenuDetailsScreen(
      {super.key, required this.menu, required this.addons});

  @override
  State<MenuDetailsScreen> createState() => _MenuDetailsScreenState();
}

class _MenuDetailsScreenState extends State<MenuDetailsScreen> {
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

  @override
  void initState() {
    super.initState();
    _currentMenu = widget.menu;
    _addons = List.from(widget.addons);
    _loadDiscounts();
    _loadMenuDiscounts();
    _initializeImages();
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    try {
      setState(() => _isLoading = true);
      await _foodService.updateMenu(_currentMenu);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to save changes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _deleteAddon(FoodAddon addon) {
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
      final menuDiscounts =
          await _discountService.getMenuDiscounts(_currentMenu.id!);
      setState(() {
        _menuDiscounts = menuDiscounts;
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
    if (discount.isActive) {
      // Deactivate the discount
      await _discountService.toggleDiscountStatus(discount.id, false);
      setState(() {
        discount.isActive = false;
      });
    } else {
      // Check if any other discount is active
      final activeDiscount = _menuDiscounts.any((menuDiscount) {
        final appliedDiscount =
            _discounts.firstWhere((d) => d.id == menuDiscount.discountId);
        return appliedDiscount.isActive;
      });

      if (activeDiscount) {
        _showError('Only one discount can be active at a time.');
        return;
      }

      // Activate the discount
      await _discountService.toggleDiscountStatus(discount.id, true);
      setState(() {
        discount.isActive = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MerchantTheme.lightTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentMenu.foodName),
          actions: [
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MenuImageGallery(
                      images: _imagePaths,
                      onImagePicked: _handleImagePicked,
                      onImageRemoved: _removeImage,
                      isLoading: _isLoading,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBasicInfoSection(),
                            const Divider(height: 32),
                            _buildPricingSection(),
                            const Divider(height: 32),
                            AddonEditor(
                              addons: _addons,
                              onAddonsChanged: (addons) {
                                setState(() => _addons = addons);
                              },
                            ),
                            const Divider(height: 32),
                            _buildDiscountSection(),
                            const Divider(height: 32),
                            _buildAvailabilitySection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _saveChanges,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
          label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
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
          Text(
            'Add-ons',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (_isEditingAddons)
            AddonManager(
              addons: _addons,
              onReorder: _reorderAddons,
              onEdit: _editAddon,
              onDelete: _deleteAddon,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addons.length,
              itemBuilder: (context, index) {
                final addon = _addons[index];
                return Card(
                  child: ListTile(
                    title: Text(addon.addonName),
                    subtitle: Text('Rp ${addon.price.toStringAsFixed(0)}'),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Implement add new addon
              },
              child: const Text('Add New Add-on'),
            ),
          ),
        ],
      ),
    );
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
          Text(
            'Discounts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  title: Text(discount.discountName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${discount.discountPercentage}% off'),
                      Text(
                        'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - ${DateFormat('MMM dd').format(discount.endDate)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: discount.isActive,
                    onChanged: (value) async {
                      await _toggleDiscount(discount);
                    },
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
            onPressed: () {
              // Implement add new discount
            },
            child: const Text('Add New Discount'),
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
}
