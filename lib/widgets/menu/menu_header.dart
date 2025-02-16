import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MenuHeader extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final VoidCallback onEdit;
  final bool isEditing;

  const MenuHeader({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.onEdit,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.bottomLeft,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.5),
          Colors.white.withOpacity(0.5),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.2, end: 0),
                ),
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: onEdit,
                ).animate().fadeIn(duration: 300.ms).scale(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              'Rp ${price.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
