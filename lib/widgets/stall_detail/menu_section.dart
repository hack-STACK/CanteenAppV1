import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Models/stall_detail_models.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:kantin/models/menu_filter_state.dart';
import 'package:kantin/enums/sort_options.dart';

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
  final Function(Menu, {List<FoodAddon> addons, String? note}) onAddToCart;
  final LoadingState loadingState;
  final String? errorMessage;
  final Map<int, List<FoodAddon>> menuAddons;
  final Set<String> favoriteMenus;
  final Function(Menu) onToggleFavorite;

  const MenuSection({
    Key? key,
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
  }) : super(key: key);

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
  RangeValues _priceRange = RangeValues(0, 1000000);

  // Add new properties for filtering and sorting
  Set<String> _activeFilters = {};
  String _searchQuery = '';

  // Use the top-level enum
  SortOption _currentSort = SortOption.recommended;

  List<Menu> get _filteredAndSortedMenus {
    List<Menu> filtered = widget.menus;

    // Apply category filter
    if (widget.selectedCategory != 'All') {
      filtered = filtered
          .where((menu) =>
              menu.type.toLowerCase() == widget.selectedCategory.toLowerCase())
          .toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((menu) =>
              menu.foodName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (menu.description?.toLowerCase() ?? '')
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Apply additional filters
    if (_activeFilters.contains('Popular')) {
      filtered = filtered.where((menu) => menu.isPopular).toList();
    }
    if (_activeFilters.contains('Vegetarian')) {
      filtered = filtered.where((menu) => menu.isVegetarian).toList();
    }
    if (_activeFilters.contains('Spicy')) {
      filtered = filtered.where((menu) => menu.isSpicy).toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case SortOption.priceAsc:
        filtered.sort((a, b) => a.price.compareTo(b.price));
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
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case SortOption.recommended:
        // Implement custom recommendation logic
        filtered.sort((a, b) {
          if (a.isRecommended != b.isRecommended) {
            return a.isRecommended ? -1 : 1;
          }
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
        break;
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
    return widget.menus.where((menu) {
      // Apply category filter
      if (widget.selectedCategory != 'All' &&
          menu.type != widget.selectedCategory.toLowerCase()) {
        return false;
      }

      // Apply tag filters
      if (_filterState.selectedTags.isNotEmpty &&
          !menu.tags.any((tag) => _filterState.selectedTags.contains(tag))) {
        return false;
      }

      // Apply price range filter
      if (menu.price < _filterState.priceRange.start ||
          menu.price > _filterState.priceRange.end) {
        return false;
      }

      // Apply search filter
      if (_filterState.searchQuery?.isNotEmpty == true) {
        final query = _filterState.searchQuery!;
        return menu.foodName.toLowerCase().contains(query) ||
            menu.description?.toLowerCase().contains(query) == true;
      }

      return true;
    }).toList();
  }

  void _sortMenus(List<Menu> menus) {
    switch (_filterState.sortBy) {
      case 'price_asc':
        menus.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        menus.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        menus.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'name':
        menus.sort((a, b) => a.foodName.compareTo(b.foodName));
        break;
    }
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

  @override
  Widget build(BuildContext context) {
    final filteredMenus = _filterMenus();
    _sortMenus(filteredMenus);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            height: constraints.maxHeight,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFilterSection(),
                AnimatedSizeAndFade(
                  child: _showFilters
                      ? _buildAdvancedFilters()
                      : const SizedBox.shrink(),
                ),
                _buildSortAndViewOptions(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Implement refresh logic if needed
                      return Future.delayed(Duration(seconds: 1));
                    },
                    child: _filteredAndSortedMenus.isEmpty
                        ? _buildEmptyState()
                        : _isGridView
                            ? _buildGridView(MediaQuery.of(context).size.width)
                            : _buildListView(),
                  ),
                ),
                if (_showScrollToTop) SizedBox(height: 72),
              ],
            ),
          );
        },
      ),
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
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8), // Added vertical padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added to minimize height
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
                '${_formatPrice(_filterState.priceRange.start)} - ${_formatPrice(_filterState.priceRange.end)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          // Slider with reduced padding
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4), // Reduced padding
            child: RangeSlider(
              values: _filterState.priceRange,
              min: 0,
              max: 1000000,
              divisions: 20,
              onChanged: (values) {
                setState(() {
                  _filterState = _filterState.copyWith(priceRange: values);
                });
              },
            ),
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

  Widget _buildFilterSection() {
    return Column(
      children: [
        _buildCategoryFilter(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('Popular', Icons.trending_up_rounded),
              _buildFilterChip('Vegetarian', Icons.eco_rounded),
              _buildFilterChip('Spicy', Icons.whatshot_rounded),
              _buildFilterChip('Best Seller', Icons.star_rounded),
            ],
          ),
        ),
      ],
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
      onSelected: (SortOption value) {
        setState(() => _currentSort = value);
      },
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

  Widget _buildGridView(double maxWidth) {
    final crossAxisCount =
        (maxWidth / 250).floor().clamp(2, 3); // Increased card width
    final spacing = 16.0;

    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(spacing),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.60, // Decreased to make cards taller
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildGridMenuItem(context, _filteredAndSortedMenus[index]),
              childCount: _filteredAndSortedMenus.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridMenuItem(BuildContext context, Menu menu) {
    final heroTag = 'menu-${menu.id}-${widget.selectedCategory}';
    return Hero(
      tag: heroTag,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => widget.onMenuTap(menu),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section with increased height
                SizedBox(
                  height: 160, // Increased from 120
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCachedImage(menu),
                      _buildImageOverlay(menu),
                      if (!menu.isAvailable) _buildOutOfStockOverlay(),
                    ],
                  ),
                ),
                // Content section with better spacing
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with more height
                        Text(
                          menu.foodName,
                          style: TextStyle(
                            fontSize: 16, // Increased from 14
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (menu.hasRating) ...[
                          SizedBox(height: 8), // Increased from 4
                          _buildRatingBadge(menu),
                        ],
                        if (menu.description?.isNotEmpty == true) ...[
                          SizedBox(height: 8), // Increased from 4
                          Expanded(
                            child: Text(
                              menu.description!,
                              style: TextStyle(
                                fontSize: 13, // Increased from 12
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        // Price and action row with better spacing
                        SizedBox(height: 12), // Increased from 8
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatPrice(menu.price),
                                    style: TextStyle(
                                      fontSize: 16, // Increased from 14
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  if (menu.originalPrice != null &&
                                      menu.originalPrice! > menu.price)
                                    Text(
                                      _formatPrice(menu.originalPrice!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (menu.isAvailable)
                              SizedBox(
                                width: 36, // Increased from 28
                                height: 36, // Increased from 28
                                child: Material(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: () => widget.onAddToCart(menu),
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 20, // Increased from 16
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
                _formatPrice(menu.price),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              if (menu.originalPrice != null &&
                  menu.originalPrice! > menu.price) ...[
                SizedBox(height: 2),
                Text(
                  _formatPrice(menu.originalPrice!),
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

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(price).replaceAll('Rp', 'Rp ');
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
    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: widget.selectedCategory == category.id
                        ? Colors.white
                        : Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
              selected: widget.selectedCategory == category.id,
              onSelected: (selected) {
                if (selected) widget.onCategorySelected(category.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
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
          ),
        ),
      ],
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

  Widget _buildListView() {
    _listAnimation.forward();
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredAndSortedMenus.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return _buildMenuItem(context, _filteredAndSortedMenus[index]);
        },
      ),
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

  Widget _buildMenuItem(BuildContext context, Menu menu) {
    final heroTag = 'menu-${menu.id}-${widget.selectedCategory}';
    return Container(
      height: 120,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 2,
        child: InkWell(
          onTap: () => widget.onMenuTap(menu),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Row(
              children: [
                // Image Section with Overlay
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: _buildCachedImage(menu),
                        ),
                        _buildOverlayGradient(),
                        if (!menu.isAvailable)
                          Center(child: _buildOutOfStockBadge()),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildQuickActions(menu),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: _buildBadgesRow(menu),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Rating
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                menu.foodName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (menu.hasRating) _buildRatingBadge(menu),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Description
                        if (menu.description?.isNotEmpty == true)
                          Expanded(
                            child: Text(
                              menu.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        // Price and Action Row
                        Row(
                          children: [
                            Column(
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
                                if (menu.originalPrice != null &&
                                    menu.originalPrice! > menu.price)
                                  Text(
                                    _formatPrice(menu.originalPrice!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                            Spacer(),
                            if (menu.isAvailable) _buildAddButton(menu),
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

  Widget _buildRatingBadge(Menu menu) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 14),
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
}

// Add this animation widget
class AnimatedSizeAndFade extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSizeAndFade({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

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
