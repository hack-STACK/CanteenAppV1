import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final int? count;
  final Color activeColor;
  final Color inactiveColor;
  final bool showCount;
  final TextStyle? countStyle;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.count,
    this.activeColor = const Color(0xFFFFD700), // Gold color
    this.inactiveColor = Colors.grey,
    this.showCount = true,
    this.countStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isHalf = index == rating.floor() && rating != rating.floor();
            final isFull = index < rating.floor();

            if (isHalf) {
              return Stack(
                children: [
                  Icon(Icons.star, size: size, color: inactiveColor),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.5, 0.5],
                      colors: [activeColor, Colors.transparent],
                    ).createShader(bounds),
                    child: Icon(Icons.star, size: size, color: Colors.white),
                  ),
                ],
              );
            }

            return Icon(
              Icons.star,
              size: size,
              color: isFull ? activeColor : inactiveColor,
            );
          }),
        ),
        if (showCount && count != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              '($count)',
              style: countStyle ??
                  TextStyle(
                    color: Colors.grey[600],
                    fontSize: size * 0.75,
                  ),
            ),
          ),
      ],
    );
  }
}
