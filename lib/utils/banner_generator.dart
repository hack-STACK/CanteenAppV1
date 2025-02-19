import 'package:flutter/material.dart';

class BannerGenerator {
  static final List<Map<String, dynamic>> _themeBanners = [
    {
      'gradient': [Color(0xFFFF8C00), Color(0xFFFF2D55)],
      'icon': Icons.local_dining,
      'text': 'Discover Great Food',
    },
    {
      'gradient': [Color(0xFF4CAF50), Color(0xFF8BC34A)],
      'icon': Icons.savings,
      'text': 'Save on Every Order',
    },
    {
      'gradient': [Color(0xFF2196F3), Color(0xFF03A9F4)],
      'icon': Icons.delivery_dining,
      'text': 'Quick Delivery',
    },
  ];

  static Widget generateBanner(int index) {
    final theme = _themeBanners[index % _themeBanners.length];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme['gradient'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              theme['icon'] as IconData,
              size: 150,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  theme['icon'] as IconData,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  theme['text'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}