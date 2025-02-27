import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class OpeningTimeInfo {
  final String timeDescription;
  final TimeOfDay time;
  final String dayOfWeek;
  final bool isSameDay;

  OpeningTimeInfo({
    required this.timeDescription,
    required this.time,
    required this.dayOfWeek,
    this.isSameDay = true,
  });
}

class TimeUtils {
  // Get next opening time description (e.g., "today at 2PM", "tomorrow at 9AM")
  static OpeningTimeInfo? getNextOpeningTime(Stan stall) {
    if (stall.openTime == null) return null;

    final now = DateTime.now();
    final currentTimeOfDay = TimeOfDay.now();

    // If already open, return null
    if (stall.isCurrentlyOpen()) return null;

    // Check if we can open later today
    final currentDay = now.weekday;
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    // Convert currentTimeOfDay to minutes past midnight
    final currentMinutes = currentTimeOfDay.hour * 60 + currentTimeOfDay.minute;

    // Convert stall opening time to minutes past midnight
    final openingMinutes = stall.openTime!.hour * 60 + stall.openTime!.minute;

    // If it's before opening time today
    if (openingMinutes > currentMinutes) {
      return OpeningTimeInfo(
        timeDescription: "today at ${_formatTime(stall.openTime!)}",
        time: stall.openTime!,
        dayOfWeek: dayNames[currentDay - 1],
        isSameDay: true,
      );
    }
    // It's after opening time, so we'll open tomorrow
    else {
      final tomorrowDay = currentDay < 7 ? currentDay + 1 : 1;
      return OpeningTimeInfo(
        timeDescription: "tomorrow at ${_formatTime(stall.openTime!)}",
        time: stall.openTime!,
        dayOfWeek: dayNames[tomorrowDay - 1],
        isSameDay: false,
      );
    }
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour${time.minute > 0 ? ':${time.minute}' : ''} $period';
  }
}
