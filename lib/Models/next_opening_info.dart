import 'package:flutter/material.dart';

class NextOpeningInfo {
  final String day;
  final TimeOfDay time;
  final String
      timeDescription; // Formatted description like "Tomorrow at 9:00 AM"
  final bool isTomorrow;
  final bool isToday;
  final DateTime date;

  NextOpeningInfo({
    required this.day,
    required this.time,
    required this.timeDescription,
    required this.isTomorrow,
    required this.isToday,
    required this.date,
  });
}
