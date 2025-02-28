import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Models/Stan_model.dart';
import '../models/next_opening_info.dart';
import '../models/stall_schedule.dart';

class TimeUtils {
  // Convert TimeOfDay to formatted string (e.g., "09:30 AM")
  static String formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final format = DateFormat.jm(); // 6:30 AM format
    return format.format(dt);
  }

  // Convert string time to TimeOfDay
  static TimeOfDay? parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    } catch (e) {
      print("Error parsing time string: $e");
      return null;
    }
  }

  // Check if current time is between start and end times
  static bool isTimeBetween(TimeOfDay start, TimeOfDay end) {
    final now = TimeOfDay.now();

    // Convert everything to minutes since midnight for comparison
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    // Handle cases where end time is on the next day
    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    }
  }

  // Get the day of week abbreviation (e.g., "Mon", "Tue")
  static String getWeekdayAbbr() {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[now.weekday - 1]; // DateTime weekday is 1-7
  }

  // Get the next opening time information for a closed stall
  static NextOpeningInfo? getNextOpeningTime(Stan stall) {
    if (stall.isCurrentlyOpen()) {
      return null; // Already open
    }

    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now); // e.g., "Monday"

    // If today's openTime is in the future, we'll open later today
    if (stall.openTime != null && stall.closeTime != null) {
      final currentTimeMinutes =
          TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
      final openTimeMinutes =
          stall.openTime!.hour * 60 + stall.openTime!.minute;

      if (openTimeMinutes > currentTimeMinutes) {
        // Will open later today
        return NextOpeningInfo(
          day: today,
          time: stall.openTime!,
          timeDescription: "Today at ${formatTimeOfDay(stall.openTime!)}",
          isTomorrow: false,
          isToday: true,
          date: now,
        );
      }
    }

    // Otherwise, find the next day when the stall will be open
    // For simplicity, we'll assume it opens tomorrow
    // In a complete implementation, we would check the schedules for each day
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDay = DateFormat('EEEE').format(tomorrow);

    if (stall.openTime != null) {
      return NextOpeningInfo(
        day: tomorrowDay,
        time: stall.openTime!,
        timeDescription: "Tomorrow at ${formatTimeOfDay(stall.openTime!)}",
        isTomorrow: true,
        isToday: false,
        date: tomorrow,
      );
    }

    return null;
  }

  // Get current day of week in three-letter format (e.g., "Mon", "Tue")
  static String getCurrentDayOfWeek() {
    final now = DateTime.now();
    // Return three-letter day abbreviation (Mon, Tue, Wed, etc.)
    return DateFormat('E').format(now);
  }

  // Check if the stall is open based on schedules
  static bool isStallOpenNow(List<StallSchedule> schedules) {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final currentTime = TimeOfDay.now();
    final currentDayOfWeek = getCurrentDayOfWeek();

    // First check for specific date schedules (overrides regular schedules)
    final specificSchedule = schedules.firstWhere(
      (schedule) =>
          schedule.specificDate != null &&
          _isSameDate(schedule.specificDate!, currentDate),
      orElse: () => schedules.firstWhere(
        // Fall back to regular weekly schedule
        (schedule) =>
            schedule.dayOfWeek == currentDayOfWeek &&
            schedule.specificDate == null,
        orElse: () =>
            StallSchedule(id: -1, stallId: -1, isOpen: false, createdAt: now),
      ),
    );

    // If we found a specific schedule that says it's closed, return false
    if (!specificSchedule.isOpen) {
      return false;
    }

    // If no open/close times are set, but is_open is true, consider it open all day
    if (specificSchedule.openTime == null ||
        specificSchedule.closeTime == null) {
      return specificSchedule.isOpen;
    }

    // Check if current time is between open and close times
    return isTimeBetween(
        specificSchedule.openTime!, specificSchedule.closeTime!);
  }

  // Helper to compare dates without time component
  static bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Get the next opening time based on schedules
  static NextOpeningInfo? getNextOpeningFromSchedules(
      List<StallSchedule> schedules) {
    final now = DateTime.now();
    final currentDayOfWeek = getCurrentDayOfWeek();
    final currentMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;

    // Sort days of week to check in order starting from today
    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final currentDayIndex = daysOfWeek.indexOf(currentDayOfWeek);
    final orderedDays = [
      ...daysOfWeek.sublist(currentDayIndex),
      ...daysOfWeek.sublist(0, currentDayIndex)
    ];

    // Check for specific dates first (next 7 days)
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final checkDateOnly =
          DateTime(checkDate.year, checkDate.month, checkDate.day);

      // Find schedule for this specific date
      final specificSchedule = schedules.firstWhere(
        (schedule) =>
            schedule.specificDate != null &&
            _isSameDate(schedule.specificDate!, checkDateOnly) &&
            schedule.isOpen,
        orElse: () =>
            StallSchedule(id: -1, stallId: -1, isOpen: false, createdAt: now),
      );

      if (specificSchedule.id != -1 && specificSchedule.openTime != null) {
        final openMinutes = specificSchedule.openTime!.hour * 60 +
            specificSchedule.openTime!.minute;

        // For today, only consider future open times
        if (i == 0 && openMinutes <= currentMinutes) {
          continue;
        }

        return NextOpeningInfo(
          day: DateFormat('EEEE').format(checkDate),
          time: specificSchedule.openTime!,
          timeDescription: i == 0
              ? "Today at ${formatTimeOfDay(specificSchedule.openTime!)}"
              : i == 1
                  ? "Tomorrow at ${formatTimeOfDay(specificSchedule.openTime!)}"
                  : "${DateFormat('EEEE').format(checkDate)} at ${formatTimeOfDay(specificSchedule.openTime!)}",
          isTomorrow: i == 1,
          isToday: i == 0,
          date: checkDate,
        );
      }

      // If no specific schedule, check regular weekly schedule
      if (i < 7) {
        // Only check regular schedules for next week
        final checkDayOfWeek = DateFormat('E').format(checkDate);
        final regularSchedule = schedules.firstWhere(
          (schedule) =>
              schedule.dayOfWeek == checkDayOfWeek &&
              schedule.specificDate == null &&
              schedule.isOpen,
          orElse: () =>
              StallSchedule(id: -1, stallId: -1, isOpen: false, createdAt: now),
        );

        if (regularSchedule.id != -1 && regularSchedule.openTime != null) {
          final openMinutes = regularSchedule.openTime!.hour * 60 +
              regularSchedule.openTime!.minute;

          // For today, only consider future open times
          if (i == 0 && openMinutes <= currentMinutes) {
            continue;
          }

          return NextOpeningInfo(
            day: DateFormat('EEEE').format(checkDate),
            time: regularSchedule.openTime!,
            timeDescription: i == 0
                ? "Today at ${formatTimeOfDay(regularSchedule.openTime!)}"
                : i == 1
                    ? "Tomorrow at ${formatTimeOfDay(regularSchedule.openTime!)}"
                    : "${DateFormat('EEEE').format(checkDate)} at ${formatTimeOfDay(regularSchedule.openTime!)}",
            isTomorrow: i == 1,
            isToday: i == 0,
            date: checkDate,
          );
        }
      }
    }

    // If no opening time found
    return null;
  }
}
