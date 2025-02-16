import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantTheme {
  static const glassBackground = Color(0x40FFFFFF);
  static const glassBorder = Color(0x80FFFFFF);
  static const accentColor = Color(0xFF2979FF);
  static const successColor = Color(0xFF00C853);
  static const warningColor = Color(0xFFFFD600);
  static const errorColor = Color(0xFFFF3D00);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final BorderRadius? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: MerchantTheme.glassBackground,
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border.all(
              color: MerchantTheme.glassBorder,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
