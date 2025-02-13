import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/StallService.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kantin/Models/menus_addon.dart';

class MyStorePage extends StatefulWidget {
  final int userId;

  const MyStorePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> with TickerProviderStateMixin {
  final StanService _stallService = StanService();
  final FoodService _foodService = FoodService();
  Stan? _stall;
  List<Menu> _menus = [];
  List<Menu> _foodMenus = [];
  List<Menu> _drinkMenus = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  // Add new properties for UI
  late TabController _menuTabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Drinks', 'Snacks'];

  // Add theme colors
  final Color primaryColor = const Color(0xFFFF3D00);
  final Color secondaryColor = const Color(0xFF2979FF);
  final Color accentColor = const Color(0xFF00C853);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color textColor = const Color(0xFF263238);

  final Map<int, List<FoodAddon>> _menuAddons = {};

  @override
  void initState() {
    super.initState();
    _menuTabController = TabController(length: _categories.length, vsync: this);
    _loadStallAndMenus();
    
    _scrollController.addListener(() {
      setState(() {
        _isCollapsed = _scrollController.hasClients && 
                       _scrollController.offset > 200;
      });
    });
  }

  Future<void> _loadStallAndMenus() async {
    try {
      setState(() => _isLoading = true);
      
      // Load stall data
      final stall = await _stallService.getStallByUserId(widget.userId);
      
      // Load menus
      final menus = await _foodService.getMenuByStanId(stall.id);
      
      // Load addons for each menu
      for (final menu in menus) {
        if (menu.id != null) {
          _menuAddons[menu.id!] = await _foodService.getAddonsForMenu(menu.id!);
        }
      }

      if (mounted) {
        setState(() {
          _stall = stall;
          _menus = menus;
          _foodMenus = menus.where((menu) => menu.type == 'food').toList();
          _drinkMenus = menus.where((menu) => menu.type == 'drink').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<Menu>> _sortMenusByType(List<Menu> menus) {
    final foodMenus = menus.where((menu) => menu.type == 'food').toList();
    final drinkMenus = menus.where((menu) => menu.type == 'drink').toList();
    return {
      'food': foodMenus,
      'drink': drinkMenus,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    if (_stall == null) {
      return _buildCreateStorePrompt();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeader(),
          _buildQuickActions(),
          _buildStats(),
          _buildMenuSection(),
          SliverToBoxAdapter(
            child: const SizedBox(
              height: 80,
            ),
          ),
        ]
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Image
            _buildStoreImage(),
            // Gradient overlay moved to _buildHeaderContent
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildHeaderContent(),
              ),
            ),
          ]
        ),
      ),
      bottom: _isCollapsed ? _buildCollapsedHeader() : null,
    );
  }

  PreferredSize _buildCollapsedHeader() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _stall?.imageUrl != null
                  ? NetworkImage(_stall!.imageUrl!)
                  : null,
              child: _stall?.imageUrl == null
                  ? Text(_stall!.ownerName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _stall!.stanName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _stall!.slot,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _stall?.imageUrl != null
                    ? NetworkImage(_stall!.imageUrl!)
                    : null,
                child: _stall?.imageUrl == null
                    ? Text(
                        _stall?.ownerName[0].toUpperCase() ?? '',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stall?.stanName ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stall?.ownerName ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stall?.description != null && _stall!.description.isNotEmpty)
            Text(
              _stall!.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _stall?.slot ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.add_box,
                    label: 'Add Menu',
                    color: accentColor,
                    onTap: () {/* TODO */},
                  ),
                  _buildActionButton(
                    icon: Icons.edit_note,
                    label: 'Edit Store',
                    color: secondaryColor,
                    onTap: () {/* TODO */},
                  ),
                  _buildActionButton(
                    icon: Icons.insights,
                    label: 'Analytics',
                    color: primaryColor,
                    onTap: () {/* TODO */},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard(
              'Today\'s Sales',
              'Rp120.000',
              Icons.payments,
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Total Orders',
              '15',
              Icons.shopping_bag,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          TabBar(
            controller: _menuTabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: _categories
                .map((category) => Tab(text: category))
                .toList(),
          ),
          SizedBox(
            height: 400, // Adjust based on your needs
            child: TabBarView(
              controller: _menuTabController,
              children: _categories.map((category) {
                final menuItems = category == 'All'
                    ? _menus
                    : _menus.where((menu) => 
                        menu.type.toLowerCase() == category.toLowerCase())
                        .toList();
                return _buildMenuGrid(menuItems);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreImage() {
    return CachedNetworkImage(
      imageUrl: _stall!.Banner_img ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _stall!.imageUrl != null
              ? NetworkImage(_stall!.imageUrl!)
              : null,
          child: _stall!.imageUrl == null
              ? AvatarGlow(
                  glowColor: Colors.blue,
                  endRadius: 60.0,
                  duration: Duration(milliseconds: 2000),
                  repeat: true,
                  showTwoGlows: true,
                  child: Material(
                    elevation: 8.0,
                    shape: CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      radius: 50.0,
                      child: Text(
                        _stall!.ownerName[0].toUpperCase(),
                        style: TextStyle(fontSize: 40.0, color: Colors.blue),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          _stall!.ownerName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildStoreImage(),
          _buildGradientOverlay(),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildProfileHeader(),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editStoreBanner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _stall!.stanName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 8),
                Text(
                  _stall!.slot,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final bool isOpen = true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStoreOverview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEditableField('Phone', _stall!.phone, Icons.phone),
            _buildEditableField('Address', _stall!.slot, Icons.location_on),
            _buildEditableField(
                'Description', _stall!.description, Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editField(label, value),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDashboard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDashboardItem('Today\'s Earnings', '\$120.00'),
                  const SizedBox(width: 16),
                  _buildDashboardItem('Total Orders', '15'),
                  const SizedBox(width: 16),
                  _buildDashboardItem('Pending Orders', '3'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 1),
                        const FlSpot(2, 4),
                        const FlSpot(3, 2),
                        const FlSpot(4, 5),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0), // Lighter grey border
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF542D), // Primary color
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF757575), // Medium grey
            ),
          ),
        ],
      ),
    );
  }

Widget _buildMenuGrid(List<Menu> menuItems) {
  return ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: menuItems.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (context, index) => _buildMenuCard(menuItems[index]),
  );
}
  Widget _buildMenuCard(Menu menu) {
    final addons = _menuAddons[menu.id] ?? [];
    final hasAddons = addons.isNotEmpty;
    final isAvailable = menu.isAvailable ?? true; // Add this field to Menu model

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Stack with Status Badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: menu.photo ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Icon(
                              menu.type == 'food' ? Icons.restaurant : Icons.local_drink,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'OUT OF\nSTOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  
                  // Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Menu Name and Type Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                menu.foodName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: isAvailable,
                              onChanged: (value) => _toggleMenuAvailability(menu),
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                        
                        // Category and Type Tags
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTag(
                              menu.type.toUpperCase(),
                              color: menu.type == 'food' 
                                  ? Colors.orange 
                                  : Colors.blue,
                            ),
                            if (menu.category != null)
                              _buildTag(
                                menu.category!,
                                color: Colors.green,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Description
                        if (menu.description != null && menu.description!.isNotEmpty)
                          Text(
                            menu.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        
                        // Price and Quick Edit
                        Row(
                          children: [
                            Text(
                              'Rp ${menu.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF542D),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 16),
                              onPressed: () => _quickEditPrice(context, menu),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(
                                width: 24,
                                height: 24,
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
            
            // Add-ons Section
            if (hasAddons) ...[
              const Divider(height: 16),
              Row(
                children: [
                  Icon(Icons.add_circle_outline, 
                       size: 16, 
                       color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${addons.length} Add-ons Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showAddons(context, menu, addons),
                    child: Text('Manage'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(60, 30),
                    ),
                  ),
                ],
              ),
            ],
            
            // Stats Section
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Today',
                    '12',
                    Icons.today,
                  ),
                  _buildStatItem(
                    'This Week',
                    '85',
                    Icons.calendar_today,
                  ),
                  _buildStatItem(
                    'Rating',
                    '4.8',
                    Icons.star,
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editMenu(context, menu, addons),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Edit Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showMenuOptions(context, menu),
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        )
        ],

    );
  }

  void _toggleMenuAvailability(Menu menu) async {
    try {
      setState(() => _isLoading = true);
      
      await _foodService.toggleMenuAvailability(
        menu.id!,
        !menu.isAvailable,
      );

      // Update local state
      setState(() {
        final index = _menus.indexWhere((m) => m.id == menu.id);
        if (index != -1) {
          _menus[index] = menu.copyWith(isAvailable: !menu.isAvailable);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu ${menu.isAvailable ? 'disabled' : 'enabled'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update menu availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickEditPrice(BuildContext context, Menu menu) {
    final priceController = TextEditingController(
      text: menu.price.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Price'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Price',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newPrice = double.parse(priceController.text);
                await _foodService.updateMenuPrice(menu.id!, newPrice);
                
                // Update local state
                setState(() {
                  final index = _menus.indexWhere((m) => m.id == menu.id);
                  if (index != -1) {
                    _menus[index] = menu.copyWith(price: newPrice);
                  }
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Price updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update price: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showMenuOptions(BuildContext context, Menu menu) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.visibility),
            title: Text(menu.isAvailable ? 'Hide Menu' : 'Show Menu'),
            onTap: () {
              Navigator.pop(context);
              _toggleMenuAvailability(menu);
            },
          ),
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('Duplicate Menu'),
            onTap: () async {
              try {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                await _foodService.duplicateMenu(menu.id!);
                await _loadStallAndMenus(); // Reload all menus
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menu duplicated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to duplicate menu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete Menu', style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete this menu?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm ?? false) {
                  Navigator.pop(context); // Close bottom sheet
                  setState(() => _isLoading = true);
                  
                  await _foodService.deleteMenu(menu.id!);
                  
                  // Update local state
                  setState(() {
                    _menus.removeWhere((m) => m.id == menu.id);
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete menu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddons(BuildContext context, Menu menu, List<FoodAddon> addons) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Make the bottom sheet adjustable
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7, // Set max height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle and header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Add-ons for ${menu.foodName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (menu.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      menu.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            
            // Add-ons list
            Expanded(
              child: ListView.builder(
                itemCount: addons.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final addon = addons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            addon.addonName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${addon.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      subtitle: addon.description != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                addon.description!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editAddon(context, menu, addon),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Add new addon button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _addNewAddon(context, menu),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add New Add-on'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewAddon(BuildContext context, Menu menu) {
    // TODO: Implement add new addon functionality
  }

  void _editMenu(BuildContext context, Menu menu, List<FoodAddon> addons) {
    // TODO: Implement edit menu functionality
  }

  void _editAddon(BuildContext context, Menu menu, FoodAddon addon) {
    // TODO: Implement edit addon functionality
  }

  Widget _buildLoadingScreen() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 150,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadStallAndMenus();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateStorePrompt() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('You don\'t have a store yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to create store page
              },
              child: const Text('Create Store'),
            ),
          ],
        ),
      ),
    );
  }

  void _editStoreBanner() {
    // TODO: Implement edit store banner functionality
  }

  void _editField(String label, String value) {
    // TODO: Implement edit field functionality
  }

  @override
  void dispose() {
    _menuTabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
