import 'package:flutter/material.dart';

class RatingIndicator extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final double size;
  final bool showCount;

  const RatingIndicator({
    super.key,
    required this.rating,
    required this.ratingCount,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: size,
          color: Colors.amber.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
