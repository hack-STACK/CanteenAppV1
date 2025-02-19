import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:flutter/services.dart';
import 'package:kantin/Models/menus_addon.dart';  // Add this import
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
    double addonPrice = selectedAddons.fold(0, (sum, addon) => sum + addon.price);
    return (menu.price + addonPrice) * quantity;
  }
}

class StallDetailPage extends StatefulWidget {
  final Stan stall;

  const StallDetailPage({Key? key, required this.stall}) : super(key: key);

  @override
  State<StallDetailPage> createState() => _StallDetailPageState();
}

class _StallDetailPageState extends State<StallDetailPage> {
  // Remove the _cartItems map since we'll use the Restaurant provider
  final FoodService _foodService = new FoodService();
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
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final _supabase = Supabase.instance.client;
  // Add this variable to store cart count
  late int _cartItemCount;

  @override
  void initState() {
    super.initState();
    _loadMenus();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Initialize cart count
    _cartItemCount = Provider.of<Restaurant>(context, listen: false).cart.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cartItemCount = Provider.of<Restaurant>(context, listen: false).cart.length;
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

  Future<void> _loadMenus() async {
    try {
      setState(() => _isLoading = true);
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
            'Foods': restaurant.menu.where((menu) => menu.type == 'food').toList(),
            'Drinks': restaurant.menu.where((menu) => menu.type == 'drink').toList(),
          };
          _menus = _categorizedMenus[_selectedCategory] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading menus: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menus: $e')),
        );
      }
    }
  }

  // Update the add to cart method to use Provider
  void _addToCart(Menu menu, {List<FoodAddon> addons = const [], String? note}) {
    // Get the Restaurant provider
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    
    // Add item to cart using the provider
    restaurant.addToCart(menu, addons: addons, note: note);
    // Show a custom snack bar with undo option
    _showCartSnackBar(menu, restaurant, addons);
  }

  void _showCartSnackBar(Menu menu, Restaurant restaurant, List<FoodAddon> addons) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Added ${menu.foodName} to cart with ${addons.length} addons'),
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
                menu.description.toLowerCase().contains(query))
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
        ].map((category) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(category),
            selected: _selectedCategory == category,
            onSelected: (selected) {
              if (selected) _filterMenus(category);
            },
          ),
        )).toList(),
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
    
    return Card(
      margin: EdgeInsets.only(
        bottom: isHorizontal ? 0 : 16,
        right: isHorizontal ? 16 : 0,
      ),
      child: InkWell(
        onTap: () => _showMenuDetail(menu),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Menu Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: menu.photo != null
                      ? Image.network(
                          menu.photo!,
                          width: double.infinity,
                          height: isHorizontal ? 120 : 160,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: isHorizontal ? 120 : 160,
                          color: Colors.grey[200],
                          child: Icon(
                            menu.type == 'food'
                                ? Icons.restaurant
                                : Icons.local_drink,
                            size: isHorizontal ? 40 : 60,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _favoriteMenus.contains(menu.foodName)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                      ),
                      color: Colors.red,
                      onPressed: () => _toggleFavorite(menu),
                    ),
                  ),
                ),
                // Category Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: menu.type == 'food'
                          ? Colors.orange.withOpacity(0.9)
                          : Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          menu.type == 'food'
                              ? Icons.restaurant
                              : Icons.local_drink,
                          color: Colors.white,
                          size: 16,
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
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.foodName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (addons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    Text(
                      'Available Add-ons:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: addons.take(3).map((addon) {
                        return Chip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          label: Text(
                            '${addon.addonName} (+${addon.price.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[200],
                        );
                      }).toList(),
                    ),
                    if (addons.length > 3)
                      Text(
                        '+${addons.length - 3} more add-ons',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ${menu.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          if (!menu.isAvailable)
                            const Text(
                              'Not Available',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: menu.isAvailable
                            ? () => _addToCart(menu)
                            : null,
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Menu detail content
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      // Menu Image
                      SliverToBoxAdapter(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: menu.photo != null
                              ? Image.network(
                                  menu.photo!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    menu.type == 'food'
                                        ? Icons.restaurant
                                        : Icons.local_drink,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      // Menu Info
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
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
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              menu.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            if (addons.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Add-ons',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...addons.map((addon) => CheckboxListTile(
                                    value: selectedAddons.contains(addon),
                                    onChanged: (checked) {
                                      setModalState(() {
                                        if (checked ?? false) {
                                          selectedAddons.add(addon);
                                        } else {
                                          selectedAddons.remove(addon);
                                        }
                                      });
                                    },
                                    title: Text(addon.addonName),
                                    subtitle: Text(
                                      '+ Rp ${addon.price.toStringAsFixed(0)}',
                                    ),
                                  )),
                            ],
                            const SizedBox(height: 24),
                            TextField(
                              controller: noteController,
                              decoration: const InputDecoration(
                                labelText: 'Special Instructions',
                                hintText: 'e.g., No onions, extra spicy',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                // Add to cart button with total price
                SafeArea(
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
                                ),
                              ),
                              Text(
                                'Rp ${(menu.price + selectedAddons.fold(0.0, (sum, addon) => sum + addon.price)).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _addToCart(
                              menu,
                              addons: selectedAddons,
                              note: noteController.text.trim(),
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.stall.Banner_img != null
                  ? Image.network(
                      widget.stall.Banner_img!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return AvatarGenerator.generateStallAvatar(
                          widget.stall.stanName,
                          size: MediaQuery.of(context).size.width,
                        );
                      },
                    )
                  : AvatarGenerator.generateStallAvatar(
                      widget.stall.stanName,
                      size: MediaQuery.of(context).size.width,
                    ),
              title: _isCollapsed ? Text(widget.stall.stanName) : null,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<Restaurant>(
                builder: (context, restaurant, _) => IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (restaurant.cart.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              restaurant.cart.length.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: restaurant.cart.isNotEmpty ? _showCart : null,
                ),
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMenus,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stall Info Card
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
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
                                        : null, // Remove AssetImage reference
                                    backgroundColor: Colors.grey[300], // Add background color
                                    child: widget.stall.imageUrl == null
                                        ? Icon(Icons.store, size: 30, color: Colors.grey[600])
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.stall.stanName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, 
                                              color: Colors.amber, 
                                              size: 16
                                            ),
                                            const Text(' 4.5 • '),
                                            const Icon(Icons.schedule, 
                                              size: 16, 
                                              color: Colors.grey
                                            ),
                                            const Text(' 5-10 mins'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(widget.stall.slot),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(widget.stall.phone),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Recommended Section
                      if (_recommendedMenus.isNotEmpty)
                        _buildMenuSection('Recommended', _recommendedMenus),

                      // Category Filter with Sort Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: _buildCategoryFilter()),
                            _buildSortingButton(),
                          ],
                        ),
                      ),

                      // Menu Items
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_menus.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _selectedCategory == 'All' 
                                  ? 'No menu items available'
                                  : 'No ${_selectedCategory.toLowerCase()} available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _menus.length,
                          itemBuilder: (context, index) => _buildMenuCard(_menus[index]),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Consumer<Restaurant>(
        builder: (context, restaurant, _) {
          if (restaurant.cart.isEmpty) {
            return const SizedBox.shrink(); // Return empty widget instead of null
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
