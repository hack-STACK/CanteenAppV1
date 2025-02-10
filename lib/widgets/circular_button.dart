import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CircularButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;

  const CircularButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? AppColors.primary,
        ),
        child: Icon(icon, color: AppColors.white),
      ),
    );
  }
}
