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

class MyStorePage extends StatefulWidget {
  final int userId;

  const MyStorePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage> {
  final StanService _stallService = StanService();
  final FoodService _foodService = FoodService();
  Stan? _stall;
  List<Menu> _menus = [];
  List<Menu> _foodMenus = [];
  List<Menu> _drinkMenus = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStall();
  }

  Future<void> _loadStall() async {
    try {
      print('Starting stall load for ID: ${widget.userId}');

      // First get the stall data
      final stall = await _stallService.getStallByUserId(widget.userId);
      print('Successfully loaded stall: ${stall.toMap()}');

      // Then get the menus using the correct stall ID
      final menus = await _foodService.getMenuByStanId(stall.id);
      print('Loaded ${menus.length} menus for stall ID: ${stall.id}');

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
      print('Error loading stall data: $e');
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSliverAppBar(),
            _buildStoreOverview(),
            _buildMiniDashboard(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMenuGrid(),
            ),
            const SizedBox(
              height: 80,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildStoreImage(),
          _buildGradientOverlay(),
          _buildStoreInfo(),
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

  Widget _buildStoreImage() {
    return CachedNetworkImage(
      imageUrl: _stall!.imageUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
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

  Widget _buildMenuGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMenuSection('Food Menu', _foodMenus),
        const SizedBox(height: 24),
        _buildMenuSection('Beverages', _drinkMenus),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Menu> menuItems) {
    if (menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        StaggeredGrid.count(
          crossAxisCount: 2,
          children: menuItems.map((menu) => _buildMenuCard(menu)).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuCard(Menu menu) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: menu.photo ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: menu.type == 'food'
                        ? const Color(0xFFFF9800) // Orange
                        : const Color(0xFF2196F3), // Blue
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    menu.type.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121), // Dark grey for text
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '\$${menu.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFFF542D), // Primary color
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement edit menu functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF542D), // Primary color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Edit Item'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                _loadStall();
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
    super.dispose();
  }
}
