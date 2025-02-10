import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class CustomNavigationBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final VoidCallback onAddPressed;

  const CustomNavigationBar({
    super.key,
    required this.navigationShell,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    print('Primary Color: ${Theme.of(context).colorScheme.primary}');
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Base Navigation Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
                Expanded(
                    child: _buildNavigationItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_outlined,
                  semanticLabel: 'Home',
                )),
                Expanded(
                    child: _buildNavigationItem(
                  context: context,
                  index: 1,
                  icon: Icons.track_changes_outlined,
                  semanticLabel: 'Tracker',
                )),
                // Placeholder for add button
                const SizedBox(width: 60),
                Expanded(
                    child: _buildNavigationItem(
                  context: context,
                  index: 2,
                  icon: Icons.notifications_outlined,
                  semanticLabel: 'Notifications',
                )),
                Expanded(
                    child: _buildNavigationItem(
                  context: context,
                  index: 3,
                  icon: Icons.settings_outlined,
                  semanticLabel: 'Settings',
                )),
              ],
            ),
          ),
        ),
        // Floating Add Button
        Positioned(
          top: -4, // Adjust this value to position the button higher
          child: _buildAddButton(context),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildNavigationItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String semanticLabel,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => navigationShell.goBranch(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          )
              .animate(target: isSelected ? 1 : 0)
              .scaleXY(begin: 1.0, end: 1.1, duration: 250.ms),
        ),
        if (isSelected) ...[
          const SizedBox(height: 4),
          Text(
            semanticLabel,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),
      ).animate().scaleXY(begin: 0.9, end: 1.0).shimmer(
          duration: 1500.ms,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
    );
  }
}
