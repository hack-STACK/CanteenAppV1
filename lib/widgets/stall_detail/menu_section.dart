import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Models/stall_detail_models.dart';
import 'package:kantin/services/menu_service.dart';
import 'package:kantin/widgets/stall_detail/menu_detail_sheet.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:kantin/models/menu_filter_state.dart';

// Move enum to top level, outside any class
enum SortOption {
  recommended,
  priceAsc,
  priceDesc,
  nameAsc,
  nameDesc,
  ratingDesc
}

class MenuSection extends StatefulWidget {
  final String selectedCategory;
  final List<MenuCategory> categories;
  final List<Menu> menus;
  final Function(String) onCategorySelected;
  final Function(Menu) onMenuTap;
  // Update the callback definition to include price parameter
  final Function(Menu, {List<FoodAddon> addons, String? note, double? price})
      onAddToCart;
  final LoadingState loadingState;
  final String? errorMessage;
  final Map<int, List<FoodAddon>> menuAddons;
  final Set<String> favoriteMenus;
  final Function(Menu) onToggleFavorite;

  const MenuSection({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.menus,
    required this.onCategorySelected,
    required this.onMenuTap,
    required this.onAddToCart,
    required this.loadingState,
    this.errorMessage,
    required this.menuAddons,
    required this.favoriteMenus,
    required this.onToggleFavorite,
  });

  @override
  State<MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection>
    with TickerProviderStateMixin {
  bool _isGridView = false;
  final _scrollController = ScrollController();
  late AnimationController _filterAnimation;
  late AnimationController _listAnimation;
  bool _showScrollToTop = false;
  String? _selectedSortOption;

  // Add new properties for filtering and sorting
  final Set<String> _activeFilters = <String>{}; // Fixed initialization
  final String _searchQuery = ''; // Fixed initialization

  // Use the top-level enum
  SortOption _currentSort = SortOption.recommended;

  List<Menu> get _filteredAndSortedMenus {
    List<Menu> filtered = widget.menus;

    // Debug current state
    print('Total menus before filtering: ${filtered.length}');
    print('Selected category: ${widget.selectedCategory}');

    // Only filter if not "all" category
    if (widget.selectedCategory.toLowerCase() != 'all') {
      filtered = filtered.where((menu) {
        // Convert both to lowercase for comparison
        final menuType = (menu.type ?? '').toLowerCase();
        final selectedType = widget.selectedCategory.toLowerCase();

        // Debug each menu item
        print('Checking menu: ${menu.foodName}');
        print('Menu type: "$menuType", Selected type: "$selectedType"');

        return menuType == selectedType;
      }).toList();
    }

    // Debug filtered results
    print('Filtered menus count: ${filtered.length}');
    for (var menu in filtered) {
      print('Filtered menu: ${menu.foodName} (${menu.type})');
    }

    return filtered;
  }

  late MenuFilterState _filterState;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showFilters = false;

  // Add unique keys for lists
  final GlobalKey _gridKey = GlobalKey(debugLabel: 'grid_key');
  final GlobalKey _listKey = GlobalKey(debugLabel: 'list_key');
  final _scrollKey = const PageStorageKey<String>('menu_section');

  // Add state for price range
  late RangeValues _priceRange;
  double _minPrice = 0;
  double _maxPrice = 1000000;
  List<Menu> _filteredMenus = [];

  @override
  void initState() {
    super.initState();
    _filterState = MenuFilterState();
    _filterAnimation = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _listAnimation = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _initializePriceRange();
    _filteredMenus = widget.menus;
  }

  void _initializePriceRange() {
    if (widget.menus.isNotEmpty) {
      _minPrice =
          widget.menus.map((m) => m.price).reduce((a, b) => a < b ? a : b);
      _maxPrice =
          widget.menus.map((m) => m.price).reduce((a, b) => a > b ? a : b);
      // Round up maxPrice to nearest thousand for better UX
      _maxPrice = ((_maxPrice + 999) ~/ 1000) * 1000.0;
    }
    _priceRange = RangeValues(_minPrice, _maxPrice);
  }

  @override
  void didUpdateWidget(MenuSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menus != oldWidget.menus) {
      _initializePriceRange();
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMenus = widget.menus.where((menu) {
        // Apply category filter
        if (widget.selectedCategory.toLowerCase() != 'all' &&
            menu.type.toLowerCase() != widget.selectedCategory.toLowerCase()) {
          return false;
        }

        // Apply price filter
        if (menu.price < _priceRange.start || menu.price > _priceRange.end) {
          return false;
        }

        // Apply search filter if exists
        if (_filterState.searchQuery?.isNotEmpty == true) {
          return menu.foodName
                  .toLowerCase()
                  .contains(_filterState.searchQuery!.toLowerCase()) ||
              (menu.description
                      ?.toLowerCase()
                      .contains(_filterState.searchQuery!.toLowerCase()) ??
                  false);
        }

        return true;
      }).toList();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _filterState = _filterState.copyWith(
        searchQuery: _searchController.text.toLowerCase(),
      );
    });
    _filterMenus();
  }

  List<Menu> _filterMenus() {
    print('DEBUG: Starting filter and sort');
    print('DEBUG: Initial menus count: ${widget.menus.length}');
    print(
        'DEBUG: Current price range: ${_priceRange.start} - ${_priceRange.end}');
    print('DEBUG: Selected category: ${widget.selectedCategory}');
    print('DEBUG: Current sort: $_currentSort');

    // First filter the menus
    List<Menu> filtered = List<Menu>.from(
        widget.menus); // Create a new list to avoid modifying original

    // Apply category filter
    if (widget.selectedCategory.toLowerCase() != 'all') {
      filtered = filtered.where((menu) {
        final bool matches =
            menu.type.toLowerCase() == widget.selectedCategory.toLowerCase();
        print(
            'DEBUG: Menu ${menu.foodName} type ${menu.type} matches category: $matches');
        return matches;
      }).toList();
    }

    // Apply price filter
    filtered = filtered.where((menu) {
      final bool inRange =
          menu.price >= _priceRange.start && menu.price <= _priceRange.end;
      print(
          'DEBUG: Menu ${menu.foodName} price ${menu.price} in range: $inRange');
      return inRange;
    }).toList();

    // Apply search filter if exists
    if (_filterState.searchQuery?.isNotEmpty == true) {
      filtered = filtered.where((menu) {
        return menu.foodName
                .toLowerCase()
                .contains(_filterState.searchQuery!.toLowerCase()) ||
            (menu.description
                    ?.toLowerCase()
                    .contains(_filterState.searchQuery!.toLowerCase()) ??
                false);
      }).toList();
    }

    print('DEBUG: After filtering: ${filtered.length} menus');

    // Sort the filtered results
    switch (_currentSort) {
      case SortOption.priceAsc:
        filtered.sort((a, b) {
          print(
              'DEBUG: Sorting price asc ${a.foodName}(${a.price}) vs ${b.foodName}(${b.price})');
          return a.price.compareTo(b.price);
        });
        break;
      case SortOption.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.nameAsc:
        filtered.sort((a, b) => a.foodName.compareTo(b.foodName));
        break;
      case SortOption.nameDesc:
        filtered.sort((a, b) => b.foodName.compareTo(a.foodName));
        break;
      case SortOption.ratingDesc:
        filtered.sort((a, b) => (b.rating).compareTo(a.rating));
        break;
      case SortOption.recommended:
        // Keep original order or implement recommendation logic
        break;
    }

    print('DEBUG: Final filtered and sorted count: ${filtered.length}');
    return filtered;
  }

  void _onSortChanged(SortOption value) {
    print('DEBUG: Sort option changed to $value');
    setState(() {
      _currentSort = value;
      // No need to call _applyFilters() here as setState will trigger build
      // which will call _filterMenus()
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterAnimation.dispose();
    _listAnimation.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _addToCart(Menu menu) async {
    // Get discounted price if available
    final MenuService menuService = MenuService();
    final double discountedPrice = await menuService.getDiscountedPrice(
      menu.id,
      menu.price,
    );

    // Call onAddToCart with the appropriate price
    widget.onAddToCart(
      menu,
      addons: [], // Pass empty addons list by default
      note: '', // Pass empty note by default
      // Use discounted price if it's different from original price
      price: discountedPrice < menu.price ? discountedPrice : menu.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAndSortedMenus = _filterMenus();
    print('DEBUG: Building with ${filteredAndSortedMenus.length} menus');

    return Column(
      // Remove mainAxisSize constraint to let it grow naturally
      mainAxisSize: MainAxisSize.min,
      children: [
        // Non-scrollable parts (keep these)
        _buildSearchBar(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showFilters ? null : 0,
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: _buildAdvancedFilters(),
          ),
        ),
        _buildSortAndViewOptions(),

        // Content area - REPLACE Expanded with normal widgets that can grow
        filteredAndSortedMenus.isEmpty
            ? _buildEmptyState()
            : _isGridView
                ? _buildGridView(MediaQuery.of(context).size.width,
                    items: filteredAndSortedMenus)
                : _buildListView(items: filteredAndSortedMenus),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _filterAnimation,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price range header and values in same row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: _minPrice,
            max: _maxPrice,
            divisions: 20,
            labels: RangeLabels(
              _formatPrice(_priceRange.start),
              _formatPrice(_priceRange.end),
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
                _applyFilters();
              });
            },
          ),
          // Tags with reduced spacing
          Wrap(
            spacing: 8,
            runSpacing: 4, // Reduced run spacing
            children: [
              _buildFilterChip('Spicy', Icons.whatshot),
              _buildFilterChip('Vegetarian', Icons.eco),
              _buildFilterChip('Halal', Icons.check_circle),
              _buildFilterChip('Popular', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: _activeFilters.contains(label),
        onSelected: (value) {
          setState(() {
            if (value) {
              _activeFilters.add(label);
            } else {
              _activeFilters.remove(label);
            }
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSortAndViewOptions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.menus.length} Items',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 12),
          _buildSortButton(),
          Spacer(),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortOption>(
      initialValue: _currentSort,
      onSelected: _onSortChanged, // Use the new method
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: SortOption.recommended,
          checked: _currentSort == SortOption.recommended,
          child: Row(
            children: [
              Icon(Icons.recommend, size: 18),
              SizedBox(width: 8),
              Text('Recommended'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.priceAsc,
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 16),
              SizedBox(width: 8),
              Text('Price: Low to High'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.priceDesc,
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 16),
              SizedBox(width: 8),
              Text('Price: High to Low'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.nameAsc,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 16),
              SizedBox(width: 8),
              Text('Name: A to Z'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.nameDesc,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 16),
              SizedBox(width: 8),
              Text('Name: Z to A'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption.ratingDesc,
          child: Row(
            children: [
              Icon(Icons.star, size: 16),
              SizedBox(width: 8),
              Text('Highest Rated'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16),
            SizedBox(width: 4),
            Text(_getSortLabel()),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_currentSort) {
      case SortOption.recommended:
        return 'Recommended';
      case SortOption.priceAsc:
        return 'Price: Low to High';
      case SortOption.priceDesc:
        return 'Price: High to Low';
      case SortOption.nameAsc:
        return 'Name: A to Z';
      case SortOption.nameDesc:
        return 'Name: Z to A';
      case SortOption.ratingDesc:
        return 'Highest Rated';
    }
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggleButton(
            icon: Icons.view_list_rounded,
            isSelected: !_isGridView,
            onTap: () => setState(() => _isGridView = false),
          ),
          _buildViewToggleButton(
            icon: Icons.grid_view_rounded,
            isSelected: _isGridView,
            onTap: () => setState(() => _isGridView = true),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(double maxWidth, {required List<Menu> items}) {
    final crossAxisCount = (maxWidth / 200).floor().clamp(2, 3);
    final spacing = 12.0;

    return GridView.builder(
      // Remove controller to let parent handle scrolling
      // controller: _scrollController,

      // Change physics to prevent independent scrolling
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true, // Add this to make grid take only the space it needs

      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.68, // More vertical space
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => AnimationConfiguration.staggeredGrid(
        position: index,
        duration: const Duration(milliseconds: 375),
        columnCount: crossAxisCount,
        child: ScaleAnimation(
          scale: 0.9,
          child: FadeInAnimation(
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: _buildGridMenuItem(context, items[index]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridMenuItem(BuildContext context, Menu menu) {
    final hasAddons = widget.menuAddons[menu.id]?.isNotEmpty ?? false;
    final heroTag = 'menu-${menu.id}';
    final theme = Theme.of(context);

    return Hero(
      tag: heroTag,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: () => widget.onMenuTap(menu),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with constrained height
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 140,
                  maxHeight: 160,
                ),
                child: Stack(
                  children: [
                    // Image with gradient overlay
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: _buildCachedImage(menu),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badges and favorite button
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Row(
                        children: [
                          if (menu.isPopular || menu.isRecommended)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (menu.isPopular)
                                      _buildAnimatedBadge(
                                        'Popular',
                                        Colors.orange.shade600,
                                        Icons.trending_up_rounded,
                                      ),
                                    if (menu.isPopular && menu.isRecommended)
                                      SizedBox(width: 4),
                                    if (menu.isRecommended)
                                      _buildAnimatedBadge(
                                        'Chef\'s Choice',
                                        Colors.green.shade600,
                                        Icons.restaurant_rounded,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(width: 8),
                          _buildQuickActionButton(menu),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content section with fixed padding
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and indicators
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              menu.foodName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (menu.isVegetarian || menu.isSpicy)
                            _buildMenuIndicators(menu),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Info badges row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (menu.hasRating) _buildEnhancedRatingBadge(menu),
                          if (menu.preparationTime != null)
                            _buildTimeBadge(menu.preparationTime!),
                          if (hasAddons) _buildCustomizableTag(),
                        ],
                      ),
                      Spacer(),
                      // Bottom section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Price section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatPrice(menu.price),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (menu.originalPrice != null &&
                                        menu.originalPrice! > menu.price)
                                      Text(
                                        _formatPrice(menu.originalPrice!),
                                        style: TextStyle(
                                          fontSize: 11,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey[400],
                                          height: 1.2,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (menu.isAvailable) _buildAddToCartButton(menu),
                            ],
                          ),
                        ],
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

  Widget _buildTimeBadge(int minutes) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 12,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4),
          Text(
            '$minutes min',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartButton(Menu menu) {
    return FutureBuilder<double>(
      future: MenuService().getDiscountedPrice(menu.id, menu.price),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        return Material(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _addToCart(menu),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListMenuItem(BuildContext context, Menu menu) {
    final hasAddons = widget.menuAddons[menu.id]?.isNotEmpty ?? false;
    final heroTag = 'menu-${menu.id}';

    return FutureBuilder<double>(
      future: MenuService().getDiscountedPrice(menu.id, menu.price),
      builder: (context, snapshot) {
        // Add debug print to see what's happening
        final discountedPrice = snapshot.data ?? menu.price;
        final discountPercentage = menu.price > 0
            ? ((menu.price - discountedPrice) / menu.price * 100).round()
            : 0;

        // Debug output to check values
        print(
            'Menu: ${menu.foodName}, Original: ${menu.price}, Discounted: $discountedPrice, Percent: $discountPercentage%');

        // Rest of the code remains the same
        return Hero(
          tag: heroTag,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onMenuTap(menu),
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 140,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section with aspect ratio and badges
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(16)),
                            child: SizedBox(
                              width: 140,
                              height: 140,
                              child: _buildCachedImage(menu),
                            ),
                          ),
                          // Gradient overlay
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.1),
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Discount badge
                          if (discountPercentage > 0)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '-$discountPercentage%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          // Out of stock overlay
                          if (!menu.isAvailable)
                            _buildEnhancedOutOfStockOverlay(),
                        ],
                      ),
                      // Content section
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row with name and favorite
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menu.foodName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            color: Colors.grey[800],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        // Badges row
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            if (menu.hasRating)
                                              _buildEnhancedRatingBadge(menu),
                                            if (menu.preparationTime != null)
                                              _buildTimeBadge(
                                                  menu.preparationTime!),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildQuickActionButton(menu),
                                ],
                              ),
                              // Description
                              if (menu.description?.isNotEmpty == true) ...[
                                SizedBox(height: 4),
                                Text(
                                  menu.description!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              Spacer(),
                              // Bottom row with price and action
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Price and customizable tag
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasAddons) _buildCustomizableTag(),
                                        SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              _formatPrice(discountedPrice),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: discountPercentage > 0
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .error
                                                    : Theme.of(context)
                                                        .primaryColor,
                                              ),
                                            ),
                                            if (discountPercentage > 0) ...[
                                              SizedBox(width: 4),
                                              Text(
                                                _formatPrice(menu.price),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Add to cart button
                                  if (menu.isAvailable)
                                    _buildAddToCartButton(menu),
                                ],
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
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, Menu menu) {
    final hasAddons = widget.menuAddons[menu.id]?.isNotEmpty ?? false;
    final heroTag = 'menu-${menu.id}';

    return Hero(
      tag: heroTag,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onMenuTap(menu),
          child: SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with fixed width
                SizedBox(
                  width: 120,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCachedImage(menu),
                      _buildOverlayGradient(),
                      if (!menu.isAvailable) _buildEnhancedOutOfStockOverlay(),
                    ],
                  ),
                ),
                // Content section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with favorite button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                menu.foodName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8),
                            _buildQuickActionButton(menu),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Badges row
                        if (menu.isPopular || menu.isRecommended)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (menu.isPopular)
                                  _buildAnimatedBadge(
                                    'Popular',
                                    Colors.orange.shade600,
                                    Icons.trending_up_rounded,
                                  ),
                                if (menu.isPopular && menu.isRecommended)
                                  SizedBox(width: 4),
                                if (menu.isRecommended)
                                  _buildAnimatedBadge(
                                    'Chef\'s Choice',
                                    Colors.green.shade600,
                                    Icons.restaurant_rounded,
                                  ),
                              ],
                            ),
                          ),
                        Spacer(),
                        // Price and Add button row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatPrice(menu.price),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (menu.originalPrice != null &&
                                      menu.originalPrice! > menu.price)
                                    Text(
                                      _formatPrice(menu.originalPrice!),
                                      style: TextStyle(
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey[500],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (menu.isAvailable)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: Material(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () => widget.onAddToCart(menu),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildMenuImage(Menu menu) {
    return _buildCachedImage(menu);
  }

  Widget _buildImageOverlay(Menu menu) {
    return Stack(
      children: [
        // Gradient overlay for better text visibility
        _buildOverlayGradient(),
        // Top actions (favorite, etc.)
        Positioned(
          top: 12,
          right: 12,
          child: _buildQuickActions(menu),
        ),
        // Bottom badges and info
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBadgesRow(menu),
              if (menu.isPopular || menu.isRecommended) SizedBox(height: 4),
              _buildImageOverlayInfo(menu),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageOverlayInfo(Menu menu) {
    return Row(
      children: [
        if (menu.preparationTime != null && menu.preparationTime! > 0) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  '${menu.preparationTime} min',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
        ],
        if (menu.hasRating)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  menu.formattedRating,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedContent(Menu menu) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Section
          Text(
            menu.foodName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          // Description
          if (menu.description?.isNotEmpty == true) ...[
            Expanded(
              child: Text(
                menu.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // Price and Action Section
          _buildPriceActionRow(menu),
        ],
      ),
    );
  }

  Widget _buildPriceActionRow(Menu menu) {
    return FutureBuilder<double>(
      future: MenuService().getDiscountedPrice(menu.id, menu.price),
      builder: (context, snapshot) {
        final discountedPrice = snapshot.data ?? menu.price;
        final hasDiscount = discountedPrice < menu.price;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Price Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatPrice(discountedPrice), // Use discounted price here
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: hasDiscount
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (hasDiscount) ...[
                    SizedBox(height: 2),
                    Text(
                      _formatPrice(menu.price),
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Add to Cart Button
            if (menu.isAvailable)
              Material(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => widget.onAddToCart(menu),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Update the existing overlay gradient for better contrast
  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.4),
            ],
            stops: [0.5, 0.8, 1.0],
          ),
        ),
      ),
    );
  }

  // Update the badge style for better visibility
  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Menu menu) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onToggleFavorite(menu),
              customBorder: CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  widget.favoriteMenus.contains(menu.foodName)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesRow(Menu menu) {
    return Wrap(
      spacing: 4,
      children: [
        if (menu.isPopular)
          _buildBadge(
            icon: Icons.trending_up_rounded,
            label: 'Popular',
            color: Colors.orange.shade600,
          ),
        if (menu.isRecommended)
          _buildBadge(
            icon: Icons.recommend_rounded,
            label: 'Recommended',
            color: Colors.green.shade600,
          ),
        if (menu.isSpicy)
          _buildBadge(
            icon: Icons.whatshot_rounded,
            label: 'Spicy',
            color: Colors.red.shade600,
          ),
      ],
    );
  }

  Widget _buildItemDetails(Menu menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Rating Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                menu.foodName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (menu.hasRating) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 2),
                    Text(
                      menu.formattedRating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 4),
        // Description
        if (menu.description?.isNotEmpty == true) ...[
          Expanded(
            child: Text(
              menu.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 8),
        ],
        // Price and Add Button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatPrice(menu.price),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (menu.isAvailable)
              Material(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => widget.onAddToCart(menu),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuContent(Menu menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Rating Row
        Row(
          children: [
            Expanded(
              child: Text(
                menu.foodName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (menu.hasRating) ...[
              Icon(Icons.star, color: Colors.amber, size: 14),
              SizedBox(width: 2),
              Text(
                menu.formattedRating,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 2),
              Text(
                '(${menu.totalRatings})',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 4),
        // Description
        if (menu.description?.isNotEmpty == true)
          Expanded(
            child: Text(
              menu.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        // Price and Action Row
        Row(
          children: [
            // Price with flexible width
            Expanded(
              child: Text(
                _formatPrice(menu.price),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            // Add button
            if (menu.isAvailable)
              SizedBox(
                width: 32,
                height: 32,
                child: Material(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => widget.onAddToCart(menu),
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Menu menu) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          menu.type == 'food'
              ? Icons.restaurant_rounded
              : Icons.local_drink_rounded,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) => _buildShimmerItem()),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    // Simplified and explicit categories
    final categories = [
      CategoryOption('all', 'All', Icons.restaurant),
      CategoryOption('food', 'Food', Icons.restaurant_menu),
      CategoryOption('drink', 'Drink', Icons.local_drink),
    ];

    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              widget.selectedCategory.toLowerCase() == category.id;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  print('Selecting category: ${category.id}');
                  widget.onCategorySelected(category.id);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200, // Give it a reasonable height
      alignment: Alignment.center,
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No items available in this category',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(widget.errorMessage ?? 'An error occurred'),
        ],
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (_showFilters) {
        _filterAnimation.forward();
      } else {
        _filterAnimation.reverse();
      }
    });
  }

  Widget _buildListView({required List<Menu> items}) {
    return ListView.separated(
      // Remove controller to let parent handle scrolling
      // controller: _scrollController,

      // Change physics to prevent independent scrolling
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true, // Add this to make list take only the space it needs

      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return _buildListMenuItem(context, items[index]);
      },
    );
  }

  Widget _buildCachedImage(Menu menu) {
    if (menu.photo == null || menu.photo!.isEmpty) {
      return _buildPlaceholder(menu);
    }

    // Validate URL
    Uri? uri;
    try {
      uri = Uri.parse(menu.photo!);
      if (!uri.hasScheme) {
        return _buildPlaceholder(menu);
      }
    } catch (e) {
      return _buildPlaceholder(menu);
    }

    return Image.network(
      menu.photo!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(menu),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildImageLoading();
      },
    );
  }

  Widget _buildAddButton(Menu menu) {
    return Material(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => widget.onAddToCart(menu),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_shopping_cart_rounded,
                  color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutOfStockBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.do_not_disturb_rounded,
            size: 14,
            color: Colors.red[600],
          ),
          SizedBox(width: 4),
          Text(
            'Out of Stock',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutOfStockOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.do_not_disturb_rounded,
                  size: 16,
                  color: Colors.red[600],
                ),
                SizedBox(width: 4),
                Text(
                  'Out of Stock',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIndicators(Menu menu) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (menu.isVegetarian)
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Tooltip(
              message: 'Vegetarian',
              child: Icon(Icons.eco, size: 16, color: Colors.green),
            ),
          ),
        if (menu.isSpicy)
          Padding(
            padding: EdgeInsets.only(left: 4),
            child: Tooltip(
              message: 'Spicy',
              child: Icon(Icons.whatshot, size: 16, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingAndTimeRow(Menu menu) {
    return Row(
      children: [
        if (menu.hasRating) _buildRatingBadge(menu),
        if (menu.hasRating && menu.preparationTime != null) SizedBox(width: 8),
        if (menu.preparationTime != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 14,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4),
              Text(
                '${menu.preparationTime} min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAddonsPreview(Menu menu) {
    final addons = widget.menuAddons[menu.id] ?? [];
    if (addons.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Options available:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: addons.take(2).map((addon) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                addon.addonName,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[800],
                ),
              ),
            );
          }).toList()
            ..addAll([
              if (addons.length > 2)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${addons.length - 2} more',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ]),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(Menu menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatPrice(menu.price),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        if (menu.originalPrice != null && menu.originalPrice! > menu.price)
          Text(
            _formatPrice(menu.originalPrice!),
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[400],
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderSection(Menu menu) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and indicators
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                menu.foodName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildMenuIndicators(menu),
          ],
        ),
        SizedBox(height: 8),
        // Rating and preparation time
        _buildRatingAndTimeRow(menu),
      ],
    );
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price).replaceAll('Rp', 'Rp ');
  }

  Widget _buildRatingBadge(Menu menu) {
    if (!menu.hasRating) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          const SizedBox(width: 2),
          Text(
            menu.formattedRating,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
          if (menu.totalRatings > 0) ...[
            const SizedBox(width: 2),
            Text(
              '(${menu.totalRatings})',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedBadge(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRatingBadge(Menu menu) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 12),
          SizedBox(width: 2),
          Text(
            menu.formattedRating,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Menu menu, bool hasAddons) {
    return Row(
      children: [
        if (menu.preparationTime != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_outlined,
                  size: 12, color: Colors.grey.shade600),
              SizedBox(width: 4),
              Text(
                '${menu.preparationTime} min',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        if (hasAddons) ...[
          if (menu.preparationTime != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('•', style: TextStyle(color: Colors.grey.shade400)),
            ),
          Text(
            'Customizable',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionButton(Menu menu) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onToggleFavorite(menu),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              widget.favoriteMenus.contains(menu.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: Colors.red,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedOutOfStockOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.not_interested, size: 16, color: Colors.red[600]),
              SizedBox(width: 8),
              Text(
                'Out of Stock',
                style: TextStyle(
                  color: Colors.red[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceStack(Menu menu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatPrice(menu.price),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).primaryColor,
          ),
        ),
        if (menu.originalPrice != null && menu.originalPrice! > menu.price)
          Text(
            _formatPrice(menu.originalPrice!),
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedAddButton(Menu menu) {
    return Material(
      color: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => widget.onAddToCart(menu),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizableTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tune_rounded,
            size: 12,
            color: Theme.of(context).primaryColor,
          ),
          SizedBox(width: 4),
          Text(
            'Customizable',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showMenuDetail(Menu menu) {
    final addons = widget.menuAddons[menu.id] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<double>(
        future: MenuService().getDiscountedPrice(menu.id, menu.price),
        builder: (context, snapshot) {
          final discountedPrice = snapshot.data ?? menu.price;
          final discountPercentage = menu.price > 0
              ? ((menu.price - discountedPrice) / menu.price * 100).round()
              : 0;
          final hasSavings = discountedPrice < menu.price;
          final savingsAmount = menu.price - discountedPrice;

          return MenuDetailSheet(
            menu: menu,
            addons: addons,
            onAddToCart: widget.onAddToCart,
            discountedPrice: discountedPrice,
            discountPercentage: discountPercentage,
            hasSavings: hasSavings,
            savingsAmount: savingsAmount,
          );
        },
      ),
    );
  }
}

// Add this class at the top of the file
class CategoryOption {
  final String id;
  final String name;
  final IconData icon;

  CategoryOption(this.id, this.name, this.icon);
}

// Add this animation widget
class AnimatedSizeAndFade extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSizeAndFade({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      child: AnimatedSwitcher(
        duration: duration,
        child: child,
      ),
    );
  }
}
