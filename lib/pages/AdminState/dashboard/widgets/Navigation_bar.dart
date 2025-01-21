import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kantin/pages/AdminState/dashboard/Order_page.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'package:kantin/pages/AdminState/dashboard/dashboard_screen.dart';
import 'package:kantin/pages/StudentState/Setting_Page.dart';

class CustomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final Function(int) onTrackerTap;

  final VoidCallback onAddPressed;

  const CustomNavigationBar({
    Key? key,
    this.currentIndex = 0,
    required this.onTrackerTap,
    required this.onTabChanged,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late PageController _pageController;
  int _currentIndex = 0;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex; // Initialize with widget.currentIndex
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index); // Navigate to the selected page
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavigationItem(
              index: 0,
              icon: Icons.home_outlined,
              semanticLabel: 'Home',
            ),
            _buildNavigationItem(
              index: 1,
              icon: Icons.track_changes_outlined,
              semanticLabel: 'Tracker',
            ),
            _buildAddButton(),
            _buildNavigationItem(
              index: 2,
              icon: Icons.notifications_outlined,
              semanticLabel: 'Notifications',
            ),
            _buildNavigationItem(
              index: 3,
              icon: Icons.settings_outlined,
              semanticLabel: 'Settings',
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required String semanticLabel,
  }) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B4AF5).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? const Color(0xFF0B4AF5) : Colors.grey,
        ),
      ).animate(target: isSelected ? 1 : 0).scaleXY(
            begin: 1.0,
            end: 1.1,
            duration: 250.ms,
          ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: widget.onAddPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B4AF5),
              const Color(0xFF0B4AF5).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B4AF5).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ).animate().scaleXY(begin: 0.9, end: 1.0).shimmer(
          duration: 1500.ms, color: const Color(0xFF0B4AF5).withOpacity(0.3)),
    );
  }
}

// In your DashboardScreen or main navigation screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _pageController; // Define _pageController here
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex); // Initialize
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose properly
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index); // Update PageView
  }

  void _onAddPressed() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () {
                  // Handle Camera action
                },
              ),
              _buildAddOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () {
                  // Handle Gallery action
                },
              ),
              _buildAddOption(
                icon: Icons.description_outlined,
                label: 'Manual',
                onTap: () {
                  // Handle Manual action
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.black87, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView for swipeable content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
          ),
          // CustomNavigationBar fixed at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomNavigationBar(
              currentIndex: _currentIndex,
              onTabChanged: _onTabChanged,
              onTrackerTap: (index) {}, // Implement if needed
              onAddPressed: () {}, // Implement if needed
            ),
          ),
        ],
      ),
    );
  }
}
