import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ImageUtils {
  /// Validates if a URL is a properly formed image URL that can be used in the app
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Handle file:/// URIs
      if (uri.scheme == 'file') {
        // For local development and testing
        final file = File(uri.path);
        return file.existsSync();
      }

      // Handle Supabase Storage URLs
      if (uri.host.contains('supabase.co') ||
          uri.path.contains('storage/v1/object/public')) {
        return true;
      }

      // Standard HTTP/HTTPS validation
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating URL: $e');
      return false;
    }
  }

  /// Creates an image widget from a URL, handling various URL types
  static Widget loadImage({
    required String? imageUrl,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final defaultPlaceholder = placeholder ?? shimmerPlaceholder();
    final defaultErrorWidget = errorWidget ?? errorPlaceholder();

    if (imageUrl == null || imageUrl.isEmpty) {
      return defaultErrorWidget;
    }

    try {
      final uri = Uri.parse(imageUrl);

      // Handle file:/// URIs
      if (uri.scheme == 'file') {
        final file = File(uri.path);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) => defaultErrorWidget,
          );
        }
        return defaultErrorWidget;
      }

      // Handle network images (including Supabase)
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => defaultPlaceholder,
        errorWidget: (context, url, error) {
          debugPrint('Error loading image ($url): $error');
          return defaultErrorWidget;
        },
      );
    } catch (e) {
      debugPrint('Error creating image widget: $e');
      return defaultErrorWidget;
    }
  }

  /// Creates a standard shimmer placeholder for images
  static Widget shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  /// Creates a standard error placeholder for images
  static Widget errorPlaceholder({
    IconData icon = Icons.image_not_supported,
    Color color = Colors.grey,
  }) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}
