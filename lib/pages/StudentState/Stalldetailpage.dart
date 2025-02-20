import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:flutter/services.dart';
import 'package:kantin/Models/menus_addon.dart'; // Add this import
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/pages/StudentState/food_cart.dart';
import 'package:kantin/utils/avatar_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import

// Add this class to manage cart items better
class CartItem {
  final Menu menu;
  final List<FoodAddon> selectedAddons;
  final String? note;
  int quantity;

  CartItem({
    required this.menu,
    this.selectedAddons = const [],
    this.note,
    this.quantity = 1,
  });

  double get totalPrice {
    double addonPrice =
        selectedAddons.fold(0, (sum, addon) => sum + addon.price);
    return (menu.price + addonPrice) * quantity;
  }
}

// Add LoadingState enum for better state management
enum LoadingState { initial, loading, loaded, error }

class StallDetailPage extends StatefulWidget {
  final Stan stall;

  const StallDetailPage({Key? key, required this.stall}) : super(key: key);

  @override
  State<StallDetailPage> createState() => _StallDetailPageState();
}

class _StallDetailPageState extends State<StallDetailPage> {
  final FoodService _foodService = FoodService();
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;

  List<Menu> _menus = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  Map<String, List<Menu>> _categorizedMenus = {
    'All': [],
    'Foods': [],
    'Drinks': [],
  };
  Map<int, List<FoodAddon>> _menuAddons = {};
  TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _sortBy = 'recommended'; // 'recommended', 'price_asc', 'price_desc'
  Set<String> _favoriteMenus = {};
  List<Menu> _recommendedMenus = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  final _supabase = Supabase.instance.client;
  // Add this variable to store cart count
  late int _cartItemCount;
  // Add this property for scroll tracking
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Initialize cart count
    _cartItemCount =
        Provider.of<Restaurant>(context, listen: false).cart.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartItemCount =
        Provider.of<Restaurant>(context, listen: false).cart.length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_isCollapsed) {
      setState(() => _isCollapsed = true);
    } else if (_scrollController.offset <= 200 && _isCollapsed) {
      setState(() => _isCollapsed = false);
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loadingState = LoadingState.loading);

      final restaurant = Provider.of<Restaurant>(context, listen: false);
      await restaurant.loadMenu(stallId: widget.stall.id);

      // Load addons for each menu
      for (var menu in restaurant.menu) {
        try {
          if (menu.id == null) continue;

          final addonsResponse = await _supabase
              .from('food_addons')
              .select()
              .eq('menu_id', menu.id!);

          if (addonsResponse != null) {
            List<FoodAddon> addons = [];

            for (var item in (addonsResponse as List)) {
              try {
                addons.add(FoodAddon.fromMap({
                  'id': item['id'],
                  'menu_id': item['menu_id'],
                  'addon_name': item['addon_name'],
                  'price': item['price'],
                  'is_required': item['is_required'],
                  'stock_quantity': item['stock_quantity'],
                  'is_available': item['is_available'],
                  'Description': item['Description'],
                }));
              } catch (e) {
                print('Error parsing addon data: $e');
                print('Problematic addon data: $item');
              }
            }

            if (addons.isNotEmpty) {
              _menuAddons[menu.id!] = addons;
            }
          }
        } catch (e, stackTrace) {
          print('Error loading addons for menu ${menu.id}: $e');
          print('Stack trace: $stackTrace');
        }
      }

      if (mounted) {
        setState(() {
          _categorizedMenus = {
            'All': restaurant.menu,
            'Foods':
                restaurant.menu.where((menu) => menu.type == 'food').toList(),
            'Drinks':
                restaurant.menu.where((menu) => menu.type == 'drink').toList(),
          };
          _menus = _categorizedMenus[_selectedCategory] ?? [];
          _loadingState = LoadingState.loaded;
        });
      }
    } catch (e) {
      print('Error loading menus: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load menu items: $e';
          _loadingState = LoadingState.error;
        });
        _showError(_errorMessage!);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _loadData,
          textColor: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddToCartSuccess(Menu menu, List<FoodAddon> addons) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Added to cart'),
                  Text(
                    '${menu.foodName} ${addons.isNotEmpty ? "with ${addons.length} add-ons" : ""}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: _showCart,
          textColor: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Update the add to cart method to use Provider
  void _addToCart(Menu menu,
      {List<FoodAddon> addons = const [], String? note}) {
    // Get the Restaurant provider
    final restaurant = Provider.of<Restaurant>(context, listen: false);

    // Add item to cart using the provider
    restaurant.addToCart(menu, addons: addons, note: note);
    // Show a custom snack bar with undo option
    _showCartSnackBar(menu, restaurant, addons);
  }

  void _showCartSnackBar(
      Menu menu, Restaurant restaurant, List<FoodAddon> addons) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Added ${menu.foodName} to cart with ${addons.length} addons'),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            restaurant.removeLastItem();
          },
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(8),
      ),
    );
  }

  void _filterMenus(String category) {
    setState(() {
      _selectedCategory = category;
      _menus = _categorizedMenus[category] ?? [];
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _menus = _categorizedMenus[_selectedCategory] ?? [];
      } else {
        _menus = (_categorizedMenus[_selectedCategory] ?? [])
            .where((menu) =>
                menu.foodName.toLowerCase().contains(query) ||
                (menu.description?.toLowerCase() ?? '').contains(query))
            .toList();
      }
    });
  }

  void _sortMenus() {
    setState(() {
      switch (_sortBy) {
        case 'price_asc':
          _menus.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          _menus.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'recommended':
          // Sort by rating or popularity if available
          break;
      }
    });
  }

  void _toggleFavorite(Menu menu) {
    setState(() {
      if (_favoriteMenus.contains(menu.foodName)) {
        _favoriteMenus.remove(menu.foodName);
      } else {
        _favoriteMenus.add(menu.foodName);
      }
    });
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _showSearch ? 60 : 0,
      child: _showSearch
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search menu...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _showSearch = false);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSortingButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      onSelected: (value) {
        setState(() {
          _sortBy = value;
          _sortMenus();
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'recommended',
          child: Text('Recommended'),
        ),
        const PopupMenuItem(
          value: 'price_asc',
          child: Text('Price: Low to High'),
        ),
        const PopupMenuItem(
          value: 'price_desc',
          child: Text('Price: High to Low'),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          'All',
          'Foods',
          'Drinks',
        ]
            .map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) _filterMenus(category);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Menu> menus) {
    if (menus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: menus.length,
            itemBuilder: (context, index) => SizedBox(
              width: 160,
              child: _buildMenuCard(menus[index], isHorizontal: true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(Menu menu, {bool isHorizontal = false}) {
    final addons = _menuAddons[menu.id] ?? [];

    return Container(
      margin: EdgeInsets.only(
        bottom: isHorizontal ? 0 : 16,
        right: isHorizontal ? 16 : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMenuDetail(menu),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Gradient Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Hero(
                        tag: 'menu_${menu.id}',
                        child: menu.photo != null
                            ? Image.network(
                                menu.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildMenuImagePlaceholder(menu),
                              )
                            : _buildMenuImagePlaceholder(menu),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Category Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: menu.type == 'food' 
                            ? Colors.orange.withOpacity(0.9)
                            : Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            menu.type == 'food' ? Icons.restaurant : Icons.local_drink,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            menu.type.capitalize(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _toggleFavorite(menu),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _favoriteMenus.contains(menu.foodName)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            menu.foodName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!menu.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price and Rating
                    Row(
                      children: [
                        Text(
                          'Rp ${menu.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (menu.hasRating) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                menu.formattedRating,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${menu.totalRatings})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      menu.description!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (addons.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // Add-ons Preview
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: addons.take(2).map((addon) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              '${addon.addonName} +${addon.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: menu.isAvailable ? () => _addToCart(menu) : null,
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuImagePlaceholder(Menu menu) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          menu.type == 'food' ? Icons.restaurant : Icons.local_drink,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  void _showMenuDetail(Menu menu) {
    final addons = _menuAddons[menu.id] ?? [];
    final TextEditingController noteController = TextEditingController();
    List<FoodAddon> selectedAddons = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Image Section
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          Hero(
                            tag: 'menu_${menu.id}',
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: menu.photo != null
                                  ? Image.network(menu.photo!, fit: BoxFit.cover)
                                  : _buildMenuImagePlaceholder(menu),
                            ),
                          ),
                          // Close Button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Material(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => Navigator.pop(context),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(Icons.close),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Title and Price Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.foodName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rp ${menu.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Favorite Button
                              IconButton(
                                icon: Icon(
                                  _favoriteMenus.contains(menu.foodName)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () => _toggleFavorite(menu),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            menu.description!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Add-ons Section
                          if (addons.isNotEmpty) ...[
                            const Text(
                              'Customize Your Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...addons.map((addon) => _buildAddonTile(
                                  addon,
                                  selectedAddons.contains(addon),
                                  (checked) {
                                    setModalState(() {
                                      if (checked ?? false) {
                                        selectedAddons.add(addon);
                                      } else {
                                        selectedAddons.remove(addon);
                                      }
                                    });
                                  },
                                )),
                            const SizedBox(height: 24),
                          ],

                          // Special Instructions
                          const Text(
                            'Special Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: 'E.g., No onions, extra spicy...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              fillColor: Colors.grey[50],
                              filled: true,
                            ),
                            maxLines: 3,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Total Price',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Rp ${(menu.price + selectedAddons.fold(0.0, (sum, addon) => sum + addon.price)).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _addToCart(
                              menu,
                              addons: selectedAddons,
                              note: noteController.text.trim(),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add to Cart',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddonTile(FoodAddon addon, bool isSelected, Function(bool?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        title: Text(
          addon.addonName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '+ Rp ${addon.price.toStringAsFixed(0)}',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // Update _showCart to use FoodCartPage
  void _showCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodCartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to cart changes using Consumer instead of watch
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_loadingState) {
      case LoadingState.initial:
      case LoadingState.loading:
        return _buildLoadingState();
      case LoadingState.error:
        return _buildErrorState();
      case LoadingState.loaded:
        return _buildLoadedState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading menu items...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(_errorMessage ?? 'An error occurred'),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildStallInfo()),
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          _buildMenuList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      elevation: _isScrolled ? 4 : 0,
      flexibleSpace: FlexibleSpaceBar(
        title: _isScrolled ? Text(widget.stall.stanName) : null,
        background: _buildStallBanner(),
      ),
      leading: BackButton(color: _isScrolled ? null : Colors.white),
      actions: [_buildCartButton()],
    );
  }

  Widget _buildStallBanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.stall.Banner_img != null
            ? Image.network(
                widget.stall.Banner_img!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
              )
            : _buildBannerPlaceholder(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) {
        if (restaurant.cart.isEmpty) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _showCart,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'View Cart (${restaurant.cart.length} items)',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStallInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: widget.stall.imageUrl != null
                    ? NetworkImage(widget.stall.imageUrl!)
                    : null,
                child: widget.stall.imageUrl == null
                    ? Text(widget.stall.stanName[0])
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stall.stanName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(widget.stall.description),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    if (_menus.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No menu items available'),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMenuCard(_menus[index]),
          ),
          childCount: _menus.length,
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) => Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: restaurant.cart.isNotEmpty ? _showCart : null,
          ),
          if (restaurant.cart.isNotEmpty)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '${restaurant.cart.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.store,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// Add this extension at the bottom of the file
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}