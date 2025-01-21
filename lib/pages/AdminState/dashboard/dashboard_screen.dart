import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/Navigation_bar.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/menu_item.dart';
import 'widgets/balance_card.dart';
import 'widgets/category_scroll.dart';
import 'widgets/profile_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/top_menu_section.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Method to handle tab changes (if needed)
  void onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

    int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            // Use the screen width for responsive design
            constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9), // 90% of screen width
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: [
                const ProfileHeaderWidget(),
                const SizedBox(height: 23),
                const CustomSearchBarWidget(),
                const SizedBox(height: 10),
                const CategoryScroll(),
                const SizedBox(height: 14),

                // Example usage
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackerScreen(),
                      ),
                    );
                  },
                  child: BalanceCardWidget(
                    currentBalance: 200000,
                    currencyCode: 'IDR',
                    historicalData: const {
                      'daily': [100, 150, 200, 180, 220, 200, 250],
                      'weekly': [1000, 1200, 1100, 1300, 1250, 1400, 1500],
                      'monthly': [5000, 5500, 6000, 5800, 6200, 6500, 7000],
                      'yearly': [
                        50000,
                        55000,
                        60000,
                        58000,
                        62000,
                        65000,
                        70000
                      ],
                    },
                    primaryColor: const Color(0xFFFF542D),
                    backgroundColor: Colors.white,
                    onCardTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackerScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TopMenuSection(
                  title: 'Featured Menus',
                  filterOptions: [
                    'Latest',
                    'Popular',
                    'Trending',
                    'Recommended'
                  ],
                  itemCount: 4,
                  accentColor: const Color(0xFFFF542D),
                  onSeeAllTap: () {
                    // Handle see all tap
                    _showAllMenusBottomSheet();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomNavigationBar(
        onTabChanged: onTabChanged,
        onAddPressed: _onAddPressed,
        onTrackerTap: (index){
          _handleNavigation(index);
        },
      ),
    );

  }
  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Home screen (dashboard)
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 1:
        // Navigate to Tracker Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackerScreen(),
          ),
        );
        break;
      case 2:
        // Notifications screen
        setState(() {
          _currentIndex = 2;
        });
        break;
      case 3:
        // Settings screen
        setState(() {
          _currentIndex = 3;
        });
        break;
    }
  }
  void _onAddPressed() {
    // Implement add functionality
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildAddMenuBottomSheet(),
    );
  }

  Widget _buildAddMenuBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New Menu Item',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAddOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  // Implement camera logic
                  Navigator.pop(context);
                },
              ),
              _buildAddOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () {
                  // Implement gallery logic
                  Navigator.pop(context);
                },
              ),
              _buildAddOption(
                icon: Icons.edit,
                label: 'Manual',
                onTap: () {
                  // Implement manual entry
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showAllMenusBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => _buildAllMenusSheet(),
    );
  }

  Widget _buildAllMenusSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'All Menus',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: 10, // Replace with actual menu count
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.food_bank),
                    ),
                    title: Text('Menu Item ${index + 1}'),
                    subtitle: Text('Description of menu item'),
                    trailing: Text('IDR 20,000'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
