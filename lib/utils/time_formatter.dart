import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class TimeFormatter {
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    try {
      // Convert to local time
      final localDateTime = dateTime.toLocal();

      if (kDebugMode) {
        print('Original DateTime: $dateTime');
        print('Local DateTime: $localDateTime');
      }

      // Format with local time
      return DateFormat('MMM d, y h:mm a').format(localDateTime);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  static String formatTimeOnly(DateTime? dateTime) {
    if (dateTime == null) return 'Time not available';

    try {
      final localTime = dateTime.toLocal();
      return DateFormat('h:mm a').format(localTime);
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return 'Time not available';
    }
  }

  static String formatDateOnly(DateTime? dateTime) {
    if (dateTime == null) return 'Date not available';

    try {
      final localTime = dateTime.toLocal();
      return DateFormat('MMM d, y').format(localTime);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'Date not available';
    }
  }

  static String formatStatus(DateTime? dateTime) {
    if (dateTime == null) return '';

    try {
      final localTime = dateTime.toLocal();
      final now = DateTime.now();
      final difference = now.difference(localTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, h:mm a').format(localTime);
      }
    } catch (e) {
      debugPrint('Error formatting status time: $e');
      return '';
    }
  }

  static String formatDeliveryEstimate(DateTime? estimatedTime) {
    if (estimatedTime == null) return 'Delivery time not available';

    final localTime = estimatedTime.toLocal();
    return DateFormat('h:mm a').format(localTime);
  }

  // Debug helper
  static void logTimeConversion(DateTime? time, String context) {
    if (kDebugMode && time != null) {
      print('\n=== Time Conversion Debug ($context) ===');
      print('UTC Time: $time');
      print('Local Time: ${time.toLocal()}');
      print('Formatted: ${formatDateTime(time)}');
      print('=====================================\n');
    }
  }
}
