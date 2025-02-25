import 'package:flutter/foundation.dart';

class ImageUrlValidator {
  /// Validates if a URL is a proper web URL (http/https)
  static bool isValidWebUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      debugPrint('Invalid URL format: $url');
      return false;
    }
  }

  /// Transforms potentially invalid URLs into valid ones or returns null
  static String? getSafeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);

      // Handle file:/// URLs - they can't be loaded directly
      if (uri.scheme == 'file') {
        debugPrint('File URL not supported: $url');
        return null;
      }

      // Check for valid http/https URLs
      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return url;
      }

      // If no scheme is provided, try adding https://
      if (!uri.hasScheme && !url.startsWith('http')) {
        final updatedUrl = 'https://$url';
        // Validate the updated URL
        if (isValidWebUrl(updatedUrl)) {
          return updatedUrl;
        }
      }

      debugPrint('URL format not supported: $url');
      return null;
    } catch (e) {
      debugPrint('Error processing URL: $e');
      return null;
    }
  }
}
