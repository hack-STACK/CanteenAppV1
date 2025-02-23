import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import
import 'package:intl/intl.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/menu_cart_item.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/Models/menus_addon.dart'; // Add this import
import 'package:kantin/pages/StudentState/OrderPage.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/pages/StudentState/food_cart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import
import 'package:kantin/widgets/stall_detail/stall_banner_header.dart';
import 'package:kantin/widgets/stall_detail/stall_info_section.dart';
import 'package:kantin/widgets/stall_detail/menu_section.dart';
import 'package:kantin/Models/stall_detail_models.dart'; // Add this import and remove local declarations
import 'package:kantin/widgets/stall_detail/review_section.dart'; // Add this import
import 'package:kantin/models/menu_filter_state.dart';
import 'package:kantin/services/menu_service.dart';

class StallDetailPage extends StatefulWidget {
  final Stan stall;
  final int studentId; // Changed from StudentId

  const StallDetailPage(
      {super.key,
      required this.stall,
      required this.studentId // Changed from StudentId
      });

  @override
  State<StallDetailPage> createState() => _StallDetailPageState();
}

class _StallDetailPageState extends State<StallDetailPage>
    with SingleTickerProviderStateMixin {
  // Remove duplicate and unnecessary keys
  // final _scrollKey = const PageStorageKey<String>('stall_detail');
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final FoodService _foodService = FoodService();
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;

  List<Menu> _menus = [];
  final bool _isLoading = true;
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  Map<String, List<Menu>> _categorizedMenus = {
    'All': [],
    'Foods': [],
    'Drinks': [],
  };
  final Map<int, List<FoodAddon>> _menuAddons = {};
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _sortBy = 'recommended'; // 'recommended', 'price_asc', 'price_desc'
  final Set<String> _favoriteMenus = {};
  final List<Menu> _recommendedMenus = [];
  final _supabase = Supabase.instance.client;
  // Add this variable to store cart count
  late int _cartItemCount;
  // Add this property for scroll tracking
  final bool _isScrolled = false;

  // Add new properties for stall details
  final List<String> _paymentMethods = ['Cash', 'QRIS', 'E-Wallet'];
  final Map<String, String> _scheduleByDay = {
    'Monday': '08:00 - 17:00',
    'Tuesday': '08:00 - 17:00',
    'Wednesday': '08:00 - 17:00',
    'Thursday': '08:00 - 17:00',
    'Friday': '08:00 - 16:30',
    'Saturday': '09:00 - 15:00',
    'Sunday': 'Closed',
  };
  final List<String> _amenities = [
    'Air Conditioning',
    'Seating Available',
    'Takeaway',
    'Halal Certified',
  ];

  // Add cart animation controller
  late AnimationController _cartAnimation;
  List<CartItem> get _cart =>
      Provider.of<Restaurant>(context, listen: false).cart;

  final List<MenuCategory> categories = [
    MenuCategory(
      id: 'all',
      name: 'All',
      icon: Icons.restaurant_menu,
    ),
    MenuCategory(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
    ),
    MenuCategory(
      id: 'drink',
      name: 'Drinks',
      icon: Icons.local_drink,
    ),
  ];

  // Add this with other state variables
  late MenuFilterState _filterState;

  // Add MenuService instance
  final MenuService _menuService = MenuService();

  @override
  void initState() {
    super.initState();
    _cartAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Initialize cart count
    _cartItemCount =
        Provider.of<Restaurant>(context, listen: false).cart.length;
    // Defer the loading to after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _loadStallMenus();
    // Initialize filter state
    _filterState = MenuFilterState();
  }

  Future<void> _loadStallMenus() async {
    try {
      // Debug print to track stall ID
      print('Loading menus for stall ID: ${widget.stall.id}');

      // Use _supabase instead of supabase
      final response = await _supabase
          .from('menu')
          .select()
          .eq('stall_id', widget.stall.id)
          .order('food_name');

      // Debug print raw response
      print('Raw menu response: $response');

      if (mounted) {
        setState(() {
          _menus = (response as List)
              .map((menu) => Menu.fromMap(menu as Map<String, dynamic>))
              .toList();

          // Debug print loaded menus
          print('Loaded ${_menus.length} menus');
          for (var menu in _menus) {
            print('Menu: ${menu.foodName}, Type: ${menu.type}');
          }
        });
      }
    } catch (e) {
      print('Error loading menus: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menu items: $e')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartItemCount =
        Provider.of<Restaurant>(context, listen: false).cart.length;
  }

  @override
  void dispose() {
    _cartAnimation.dispose();
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
          final addonsResponse = await _supabase
              .from('food_addons')
              .select()
              .eq('menu_id', menu.id);

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
            _menuAddons[menu.id] = addons;
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

  // Update the _addToCart method signature
  void _addToCart(
    Menu menu, {
    int quantity = 1, // Add quantity parameter with default value
    List<FoodAddon> addons = const [],
    String? note,
    double? price,
  }) async {
    print('\n=== Adding to Cart ===');
    print('Menu: ${menu.foodName}');
    print('Original Price: ${menu.price}');

    // Force fetch latest discount
    await menu.fetchDiscount();

    // Wait a moment for the discount to be applied
    await Future.delayed(const Duration(milliseconds: 100));

    print('After fetching discount:');
    print('Has Discount: ${menu.hasDiscount}');
    print(
        'Discounted Price: ${menu.hasDiscount ? menu.effectivePrice : "No discount"}');
    print('Discount Percentage: ${menu.discountPercent}%');

    final restaurant = Provider.of<Restaurant>(context, listen: false);
    restaurant.addToCart(
      menu,
      quantity: quantity, // Pass quantity parameter
      addons: addons,
      note: note,
    );

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
      _applyFilters();
    });
  }

  void _applyFilters() {
    final filteredMenus = _categorizedMenus[_selectedCategory]?.where((menu) {
          // Only apply category filter
          if (_selectedCategory.toLowerCase() != 'all' &&
              menu.type.toLowerCase() != _selectedCategory.toLowerCase()) {
            return false;
          }
          return true;
        }).toList() ??
        [];

    setState(() {
      _menus = filteredMenus;
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Hero(
                        tag: 'menu_${menu.id}',
                        child: _loadMenuImage(menu),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                            menu.type == 'food'
                                ? Icons.restaurant
                                : Icons.local_drink,
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
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
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
                        onPressed: menu.isAvailable
                            ? () => _addToCart(
                                  menu,
                                  quantity: 1, // Add quantity parameter
                                )
                            : null,
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

  // Add better image URL validation
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Update image loading method
  Widget _loadMenuImage(Menu menu) {
    if (menu.photo == null || menu.photo!.isEmpty) {
      return _buildMenuImagePlaceholder(menu);
    }

    try {
      final uri = Uri.parse(menu.photo!);
      if (!uri.hasScheme ||
          (!uri.scheme.startsWith('http') && !uri.scheme.startsWith('https'))) {
        return _buildMenuImagePlaceholder(menu);
      }

      return Image.network(
        menu.photo!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildMenuImagePlaceholder(menu),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } catch (e) {
      return _buildMenuImagePlaceholder(menu);
    }
  }

  void _showMenuDetail(Menu menu) async {
    // Fetch discount at the start
    await menu.fetchDiscount();

    final addons = _menuAddons[menu.id] ?? [];
    final TextEditingController noteController = TextEditingController();
    // Initialize selectedAddons list
    final List<FoodAddon> selectedAddons = [];
    // Get active discounts from menu (handle null case)
    final activeDiscounts = menu.discounts ?? [];

    // Calculate discount details with proper null safety
    final originalPrice = menu.price;
    final discountedPrice = menu.hasDiscount ? menu.effectivePrice : menu.price;
    final hasDiscount = menu.hasDiscount && discountedPrice < originalPrice;
    final discountPercentage = hasDiscount
        ? ((originalPrice - discountedPrice) / originalPrice * 100).round()
        : 0;
    final savingsAmount = hasDiscount ? originalPrice - discountedPrice : 0.0;

    // Calculate total price including addons
    double calculateTotalPrice(List<FoodAddon> selectedAddons) {
      return discountedPrice +
          selectedAddons.fold(0.0, (sum, addon) => sum + (addon.price ?? 0.0));
    }

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
              // Image Section with Hero animation
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Hero(
                      tag: 'menu_${menu.id}',
                      child: _loadMenuImage(menu),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  // Enhanced Discount badge if applicable
                  if (hasDiscount)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'SAVE $discountPercentage%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Content Section
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Title Section
                    Text(
                      menu.foodName ?? 'Unnamed Item',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (menu.description?.isNotEmpty ?? false)
                      Text(
                        menu.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Enhanced Price Display Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            hasDiscount ? Colors.red.shade50 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasDiscount
                              ? Colors.red.shade200
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original Price (if discounted)
                          if (hasDiscount) ...[
                            Row(
                              children: [
                                Text(
                                  'Original Price:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'id',
                                    symbol: 'Rp ',
                                    decimalDigits: 0,
                                  ).format(originalPrice),
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Current Price
                          Row(
                            children: [
                              Text(
                                hasDiscount ? 'Discounted Price:' : 'Price:',
                                style: TextStyle(
                                  color: hasDiscount
                                      ? Colors.red.shade700
                                      : Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(discountedPrice),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: hasDiscount
                                      ? Colors.red.shade700
                                      : Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(height: 8),
                            Text(
                              'You save: ${NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(savingsAmount)}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Active Discounts Section
                    if (activeDiscounts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Active Promotions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...activeDiscounts.map((discount) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${discount.discountName} (${discount.discountPercentage.toStringAsFixed(0)}% off)',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],

                    // Add-ons Section
                    if (addons.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Add-ons',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...addons.map((addon) => _buildAddonTile(
                            addon,
                            selectedAddons.contains(addon),
                            (selected) => setModalState(() {
                              if (selected ?? false) {
                                selectedAddons.add(addon);
                              } else {
                                selectedAddons.remove(addon);
                              }
                            }),
                          )),
                    ],

                    // Special Instructions
                    const SizedBox(height: 24),
                    const Text(
                      'Special Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add notes for your order (optional)',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom Bar with Total Price
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
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(calculateTotalPrice(selectedAddons)),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount
                                    ? Colors.red.shade600
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (menu.isAvailable ?? false)
                              ? () {
                                  _addToCart(
                                    menu,
                                    quantity: 1, // Explicitly pass quantity
                                    addons: selectedAddons,
                                    note: noteController.text.trim(),
                                  );
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                hasDiscount ? Colors.red.shade600 : null,
                          ),
                          child: Text(
                            (menu.isAvailable ?? false)
                                ? 'Add to Cart'
                                : 'Out of Stock',
                            style: const TextStyle(fontSize: 16),
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

  Widget _buildAddonTile(
      FoodAddon addon, bool isSelected, Function(bool?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
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
      MaterialPageRoute(
          builder: (context) => FoodCartPage(
                StudentId: widget.studentId,
              )),
    );
  }

  // Add new time formatting helper methods
  String _formatLocalTime(TimeOfDay? time) {
    if (time == null) return 'N/A';

    try {
      // Get current date for combining with TimeOfDay
      final now = DateTime.now();
      final dateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Convert to local time
      final localDateTime = dateTime.toLocal();

      if (kDebugMode) {
        print('Original time: ${time.format(context)}');
        print('Local time: ${DateFormat('hh:mm a').format(localDateTime)}');
      }

      return DateFormat('hh:mm a').format(localDateTime);
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return 'Time not available';
    }
  }

  String _formatScheduleTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'Closed';

    try {
      final times = timeString.split(' - ');
      if (times.length != 2) return timeString;

      final openTime = _parseTimeString(times[0]);
      final closeTime = _parseTimeString(times[1]);

      return '${_formatLocalTime(openTime)} - ${_formatLocalTime(closeTime)}';
    } catch (e) {
      debugPrint('Error parsing schedule time: $e');
      return timeString;
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      debugPrint('Error parsing time string: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            child: NestedScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return <Widget>[
                  StallBannerHeader(
                    stall: widget.stall,
                    isCollapsed: _isCollapsed,
                    onCartTap: _showCart,
                    cartItemCount: _cartItemCount,
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        StallInfoSection(
                          stall: widget.stall,
                          metrics: _buildMetrics(),
                          schedule: _scheduleByDay,
                          amenities: _amenities,
                          paymentMethods: _paymentMethods,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ReviewSection(
                            stall: widget.stall,
                            onSeeAllReviews: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: MenuSection(
                key: ValueKey('menu_section_${widget.stall.id}'),
                selectedCategory: _selectedCategory,
                categories: categories,
                menus: _menus,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                },
                onMenuTap: _showMenuDetail,
                onAddToCart: _addToCart, // Now the signatures match
                loadingState: _loadingState,
                errorMessage: _errorMessage,
                menuAddons: _menuAddons,
                favoriteMenus: _favoriteMenus,
                onToggleFavorite: _toggleFavorite,
              ),
            ),
          ),
          if (_loadingState == LoadingState.loading) _buildLoadingOverlay(),
        ],
      ),
      bottomNavigationBar: _buildCartBar(),
    );
  }

  List<MenuCategory> _buildCategories() {
    return [
      MenuCategory(
        id: 'all',
        name: 'All',
        icon: Icons.restaurant_menu,
      ),
      MenuCategory(
        id: 'food',
        name: 'Foods',
        icon: Icons.lunch_dining,
      ),
      MenuCategory(
        id: 'drink',
        name: 'Drinks',
        icon: Icons.local_drink,
      ),
      if (_categorizedMenus['Bestsellers']?.isNotEmpty ?? false)
        MenuCategory(
          id: 'bestsellers',
          name: 'Bestsellers',
          icon: Icons.star,
        ),
    ];
  }

  // Update _buildMetrics to use new time formatting
  List<StallMetric> _buildMetrics() {
    if (kDebugMode) {
      print(
          'Building metrics with stall opening time: ${widget.stall.openTime}');
    }

    return [
      // ...existing metrics...
      StallMetric(
        icon: Icons.access_time,
        value: _formatLocalTime(widget.stall.openTime),
        label: 'Opens',
        color: Colors.blue,
      ),
      // ...remaining metrics...
    ];
  }

  // Update schedule display
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _scheduleByDay.entries.map((entry) {
        final isToday = DateFormat('EEEE').format(DateTime.now()) == entry.key;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _formatScheduleTime(entry.value),
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: entry.value == 'Closed'
                        ? Colors.red
                        : isToday
                            ? Theme.of(context).primaryColor
                            : null,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading Menu...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) {
        final cartItems = restaurant.cart;

        if (cartItems.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate totals with discounts
        double cartSubtotal = 0.0;
        double totalSavings = 0.0;
        int totalItems = 0;

        // Debug prints to track calculations
        print('\n=== Cart Calculation Debug ===');

        for (var item in cartItems) {
          // Ensure we're using the correct prices
          final originalItemPrice = item.menu.price;
          final effectiveItemPrice = item.menu.effectivePrice;

          // Calculate per-item amounts
          final originalTotal = originalItemPrice * item.quantity;
          final effectiveTotal = effectiveItemPrice * item.quantity;

          // Add addon costs
          final addonsCost = item.selectedAddons
              .fold(0.0, (sum, addon) => sum + (addon.price * item.quantity));

          // Update running totals
          cartSubtotal += effectiveTotal + addonsCost;

          // Only calculate savings if there's actually a discount
          if (item.menu.hasDiscount) {
            final itemSavings = originalTotal - effectiveTotal;
            totalSavings += itemSavings;

            // Debug print for this item
            print('Item: ${item.menu.foodName}');
            print('Original Price: $originalItemPrice');
            print('Effective Price: $effectiveItemPrice');
            print('Quantity: ${item.quantity}');
            print('Savings: $itemSavings');
          }

          totalItems += item.quantity;
        }

        // Find all active discount percentages and their total savings
        final activeDiscounts =
            totalSavings > 0 ? 'Save ${_formatPrice(totalSavings)}' : '';

        print('Final Calculations:');
        print('Total Items: $totalItems');
        print('Subtotal: $cartSubtotal');
        print('Total Savings: $totalSavings');
        print('Active Discounts: $activeDiscounts');
        print('=========================\n');

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Material(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              child: InkWell(
                onTap: _showCart,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12), // Reduced padding
                  child: Row(
                    children: [
                      // Cart Icon with Badge
                      SizedBox(
                        width: 32, // Fixed width for icon section
                        child: Stack(
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                color: Colors.white, size: 24),
                            if (totalItems > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 14,
                                    minHeight: 14,
                                  ),
                                  child: Text(
                                    '$totalItems',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Middle section with prices
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'} in cart',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _formatPrice(cartSubtotal),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (totalSavings > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[400],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.savings,
                                            color: Colors.white, size: 10),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Save ${_formatPrice(totalSavings)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // View Cart button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'N/A';

    // Dapatkan waktu sekarang untuk mendapatkan tanggal lokal
    final now = DateTime.now();

    // Buat DateTime dengan jam dan menit yang diberikan
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Konversi ke waktu lokal
    final localTime = dateTime.toLocal();

    // Format waktu lokal dalam format 12 jam (AM/PM)
    return DateFormat('hh:mm a').format(localTime);
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(price)}';
  }
}
