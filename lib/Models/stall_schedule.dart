import 'package:flutter/material.dart';

class StallSchedule {
  final int id;
  final int stallId;
  final String? dayOfWeek; // Mon, Tue, Wed, etc.
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final bool isOpen;
  final DateTime? specificDate; // For special days
  final DateTime createdAt;

  StallSchedule({
    required this.id,
    required this.stallId,
    this.dayOfWeek,
    this.openTime,
    this.closeTime,
    required this.isOpen,
    this.specificDate,
    required this.createdAt,
  });

  factory StallSchedule.fromMap(Map<String, dynamic> map) {
    return StallSchedule(
      id: map['id'] as int,
      stallId: map['stall_id'] as int,
      dayOfWeek: map['day_of_week'] as String?,
      openTime: _parseTimeString(map['open_time']),
      closeTime: _parseTimeString(map['close_time']),
      isOpen: map['is_open'] as bool,
      specificDate: map['specific_date'] != null
          ? DateTime.parse(map['specific_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stall_id': stallId,
      'day_of_week': dayOfWeek,
      'open_time': openTime != null
          ? '${openTime!.hour.toString().padLeft(2, '0')}:${openTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'close_time': closeTime != null
          ? '${closeTime!.hour.toString().padLeft(2, '0')}:${closeTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'is_open': isOpen,
      'specific_date': specificDate?.toIso8601String().split('T').first,
    };
  }

  static TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      print('Error parsing time string: $e');
      return null;
    }
  }
}
