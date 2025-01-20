import 'package:flutter/material.dart';
import 'menu_item.dart';

class TopMenuSection extends StatelessWidget {
  const TopMenuSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 68.5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF532D).withOpacity(0.37),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top menus',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Figtree',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF542D)),
                ),
                child: Row(
                  children: const [
                    Text(
                      'Latest',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const MenuItem(),
          const SizedBox(height: 8),
          const MenuItem(),
          const SizedBox(height: 8),
          const MenuItem(),
        ],
      ),
    );
  }
}