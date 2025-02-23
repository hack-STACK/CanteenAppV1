import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DiscountBadge extends StatelessWidget {
  final double discountPercentage;
  final bool compact;

  const DiscountBadge({
    super.key,
    required this.discountPercentage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (discountPercentage <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade500,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${discountPercentage.round()}% OFF',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ).animate().scale().fadeIn();
  }
}
