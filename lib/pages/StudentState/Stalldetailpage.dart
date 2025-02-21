import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/Models/menus_addon.dart'; // Add this import
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/pages/StudentState/food_cart.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import
import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kantin/widgets/stall_detail/stall_banner_header.dart';
import 'package:kantin/widgets/stall_detail/stall_info_section.dart';
import 'package:kantin/widgets/stall_detail/menu_section.dart';
import 'package:kantin/Models/stall_detail_models.dart'; // Add this import and remove local declarations
import 'package:kantin/widgets/stall_detail/review_section.dart'; // Add this import

class StallDetailPage extends StatefulWidget {
  final Stan stall;
  final int StudentId;

  const StallDetailPage(
      {super.key, required this.stall, required this.StudentId});

  @override
  State<StallDetailPage> createState() => _StallDetailPageState();
}

class _StallDetailPageState extends State<StallDetailPage>
    with SingleTickerProviderStateMixin {
  // Replace individual keys with a ValueKey
  final _scrollKey = const PageStorageKey<String>('stall_detail');
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
          if (menu.id == null) continue;

          final addonsResponse = await _supabase
              .from('food_addons')
              .select()
              .eq('menu_id', menu.id!);

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

    // Add item to cart using the provider with named parameters
    restaurant.addToCart(
      menu,
      quantity: 1,
      selectedAddons: addons,
      note: note,
      addons: _menuAddons[menu.id] ?? [], // Add the addons parameter
    );

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
                            ? () => _addToCart(menu) // Updated call
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
                              child: _loadMenuImage(menu),
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
                StudentId: widget.StudentId,
              )),
    );
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
              physics: const ClampingScrollPhysics(),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
              ],
              body: MenuSection(
                selectedCategory: _selectedCategory,
                categories: _buildCategories(),
                menus: _menus,
                onCategorySelected: _filterMenus,
                onMenuTap: _showMenuDetail,
                onAddToCart: _addToCart,
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

  List<StallMetric> _buildMetrics() {
    return [
      StallMetric(
        icon: Icons.star,
        value: widget.stall.rating?.toStringAsFixed(1) ?? 'N/A',
        label: '${widget.stall.reviewCount} Reviews',
        color: Colors.amber,
      ),
      StallMetric(
        icon: Icons.access_time,
        value: _formatTime(widget.stall.openTime),
        label: 'Opens',
        color: Colors.blue,
      ),
      StallMetric(
        icon: Icons.location_on,
        value: '${widget.stall.distance?.toStringAsFixed(0) ?? "?"} m',
        label: 'Distance',
        color: Colors.green,
      ),
      StallMetric(
        icon: Icons.menu_book,
        value: '${_menus.length}',
        label: 'Items',
        color: Colors.purple,
      ),
    ];
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
    return AnimatedBuilder(
      animation: _cartAnimation,
      builder: (context, child) => AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: Offset(0, _cart.isEmpty ? 1 : 0),
        child: Container(
          padding: const EdgeInsets.all(16).copyWith(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
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
          child: ElevatedButton.icon(
            onPressed: _showCart,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.shopping_cart),
            label: Text(
              'View Cart (${_cart.length} items) · ${_formatPrice(_calculateTotal())}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'N/A';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final adjustedHour = time.hour > 12 ? time.hour - 12 : time.hour;
    return '$adjustedHour:$minute $period';
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${formatter.format(price)}';
  }

  double _calculateTotal() {
    return _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
}

// Add this extension at the bottom of the file
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
