// lib/widgets/store_profile.dart
import 'package:flutter/material.dart';
import 'package:kantin/widgets/circular_button.dart';

class StoreProfile extends StatelessWidget {
  const StoreProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 85,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage:
                      AssetImage("assets/images/img_ellipse_1.png"),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(10, 10),
              child: CircularButton(
                icon: "assets/images/img_frame.svg",
                size: 40,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          "Stall Name",
          style: AppTextStyles.headerTitle,
        ),
        const SizedBox(height: 8),
        const Text(
          "Authentic Local Cuisine",
          style: AppTextStyles.headerSubtitle,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoChip(Icons.star_rounded, "4.8", "Rating"),
            const SizedBox(width: 16),
            _buildInfoChip(Icons.access_time_rounded, "15-20", "min"),
            const SizedBox(width: 16),
            _buildInfoChip(
                Icons.local_fire_department_rounded, "Popular", null),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, String? subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
