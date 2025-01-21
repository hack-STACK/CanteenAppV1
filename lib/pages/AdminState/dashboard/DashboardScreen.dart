import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/Navigation_bar.dart';

class DashboardScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomNavigationBar(
              navigationShell: navigationShell,
              onAddPressed: () {
                _showAddMenu(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildAddMenuBottomSheet(),
      ),
    );
  }

  Widget _buildAddMenuBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          const SizedBox(height: 20),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 200.ms).fadeIn();
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0B4AF5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0B4AF5),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          .animate()
          .slideY(begin: 0.2, duration: 200.ms, delay: 100.ms)
          .fadeIn(delay: 100.ms),
    );
  }
}
