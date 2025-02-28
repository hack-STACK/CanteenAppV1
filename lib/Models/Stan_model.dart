import 'package:flutter/material.dart';
import 'package:kantin/Models/discount_model.dart';

class Stan {
  final int id;
  final String stanName; // maps to nama_stalls
  final String ownerName; // maps to nama_pemilik
  final String phone; // maps to no_telp
  final int userId; // maps to id_user
  final String description; // maps to deskripsi
  final String slot; // maps to slot
  final String? imageUrl; // maps to image_url
  final String? Banner_img; // maps to Banner_img
  final double? rating; // Add rating field
  bool isOpen; // Changed to non-final to allow update through setScheduleInfo
  final TimeOfDay? openTime; // New field
  final TimeOfDay? closeTime; // New field
  List<Discount>? activeDiscounts;
  final String? cuisineType;
  final int reviewCount;
  final bool isBusy;
  final double? distance;
  final bool isManuallyOpen; // Add this property for manual override
  final String? category; // Add category property

  // Add map to store schedule information
  Map<String, dynamic>? _scheduleInfo;

  // Default schedule constants
  static const Map<String, dynamic> DEFAULT_SCHEDULE = {
    'is_open': true,
    'open_time': '08:00:00', // 8 AM default opening time
    'close_time': '17:00:00', // 5 PM default closing time
    'is_default': true // Flag to indicate this is a default schedule
  };

  // Default business days - 1 to 5 (Monday to Friday)
  static const List<int> DEFAULT_BUSINESS_DAYS = [1, 2, 3, 4, 5];

  Stan({
    required this.id,
    required this.stanName,
    required this.ownerName,
    required this.phone,
    required this.userId,
    required this.description,
    required this.slot,
    this.imageUrl,
    this.Banner_img,
    this.rating, // Include in constructor
    this.isOpen = true, // Default to true
    this.openTime,
    this.closeTime,
    this.activeDiscounts,
    this.cuisineType,
    this.reviewCount = 0,
    this.isBusy = false,
    this.distance,
    this.isManuallyOpen = true, // Default to true
    this.category, // Include category in constructor
  });

  // Add this method to set schedule information
  void setScheduleInfo(Map<String, dynamic>? scheduleInfo) {
    // If no schedule provided, use default schedule
    if (scheduleInfo == null || scheduleInfo.isEmpty) {
      // Check if today is a default business day
      final now = DateTime.now();
      final isBusinessDay = DEFAULT_BUSINESS_DAYS.contains(now.weekday);

      if (isBusinessDay) {
        _scheduleInfo = Map<String, dynamic>.from(DEFAULT_SCHEDULE);
        // Update open status based on current time and default hours
        _updateOpenStatusWithDefaultSchedule();
      } else {
        // Weekend or non-business day - closed by default
        _scheduleInfo = {
          'is_open': false,
          'is_default': true,
          'reason': 'Closed on weekends'
        };
      }
    } else {
      _scheduleInfo = scheduleInfo;
    }

    // Update isOpen based on schedule info
    isOpen = _scheduleInfo!.containsKey('is_open')
        ? _scheduleInfo!['is_open'] as bool
        : false;
  }

  // Helper method to update open status based on default schedule
  void _updateOpenStatusWithDefaultSchedule() {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    final openTime = _scheduleInfo!['open_time'] as String;
    final closeTime = _scheduleInfo!['close_time'] as String;

    // Check if current time is within operating hours
    _scheduleInfo!['is_open'] = currentTime.compareTo(openTime) >= 0 &&
        currentTime.compareTo(closeTime) <= 0;
  }

  // Add this method to check if stall is open according to schedule
  bool isScheduleOpen() {
    if (_scheduleInfo == null) {
      // If no schedule info at all, apply default schedule first
      setScheduleInfo(null);
    }

    return _scheduleInfo != null &&
        (_scheduleInfo!['is_open'] as bool? ?? false);
  }

  // Add public getter methods for schedule information
  Map<String, dynamic>? get scheduleInfo => _scheduleInfo;

  String? get openTimeString => _scheduleInfo?['open_time'] as String?;
  String? get closeTimeString => _scheduleInfo?['close_time'] as String?;
  bool get isUsingDefaultSchedule => _scheduleInfo?['is_default'] == true;

  factory Stan.fromMap(Map<String, dynamic> map) {
    String? openTimeStr = map['open_time'];
    String? closeTimeStr = map['close_time'];

    TimeOfDay? parseTimeString(String? timeStr) {
      if (timeStr == null) return null;
      try {
        final parts = timeStr.split(':');
        if (parts.length != 2) return null;
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        print('Error parsing time: $e');
        return null;
      }
    }

    // Handle discounts with better error handling
    List<Discount>? discounts;
    if (map['discounts'] != null) {
      try {
        discounts = (map['discounts'] as List)
            .map((discount) {
              try {
                return Discount.fromMap(discount as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing individual discount: $e');
                return null;
              }
            })
            .whereType<Discount>() // This removes any null values
            .where((discount) =>
                discount.isActive && discount.endDate.isAfter(DateTime.now()))
            .toList();
      } catch (e) {
        print('Error parsing discounts list: $e');
        discounts = [];
      }
    }

    try {
      return Stan(
        id: map['id'] as int,
        stanName: map['nama_stalls'] as String? ?? '',
        ownerName: map['nama_pemilik'] as String? ?? '',
        phone: map['no_telp'] as String? ?? '',
        userId: map['id_user'] as int,
        description: map['deskripsi'] as String? ?? '',
        slot: map['slot'] as String? ?? '',
        imageUrl: map['image_url'] as String?,
        Banner_img: map['Banner_img'] as String?,
        rating: map['average_rating'] != null
            ? (map['average_rating'] as num).toDouble()
            : (map['rating'] != null
                ? (map['rating'] as num).toDouble()
                : null),
        isOpen: map['is_open'] as bool? ?? true,
        openTime: parseTimeString(openTimeStr),
        closeTime: parseTimeString(closeTimeStr),
        activeDiscounts: discounts,
        cuisineType: map['cuisine_type'] as String?,
        reviewCount: map['review_count'] as int? ?? 0,
        isBusy: map['is_busy'] as bool? ?? false,
        distance: map['distance'] != null
            ? (map['distance'] as num).toDouble()
            : null,
        isManuallyOpen: map['is_manually_open'] as bool? ?? true,
        category: map['category'] as String?, // Extract category from map
      );
    } catch (e) {
      print('Error creating Stan from map: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    String? timeToString(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    return {
      'id': id,
      'nama_stalls': stanName,
      'nama_pemilik': ownerName,
      'no_telp': phone,
      'id_user': userId,
      'deskripsi': description,
      'slot': slot,
      'image_url': imageUrl,
      'Banner_img': Banner_img,
      'rating': rating,
      'is_open': isOpen,
      'open_time': timeToString(openTime),
      'close_time': timeToString(closeTime),
      'cuisine_type': cuisineType,
      'review_count': reviewCount,
      'is_busy': isBusy,
      'distance': distance,
      'is_manually_open': isManuallyOpen,
      'category': category, // Add category to map
    };
  }

  Stan copyWith({
    int? id,
    String? stanName,
    String? ownerName,
    String? phone,
    int? userId,
    String? description,
    String? slot,
    String? imageUrl,
    String? Banner_img,
    double? rating,
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    List<Discount>? activeDiscounts,
    String? cuisineType,
    int? reviewCount,
    bool? isBusy,
    double? distance,
    bool? isManuallyOpen,
    String? category,
  }) {
    return Stan(
      id: id ?? this.id,
      stanName: stanName ?? this.stanName,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      slot: slot ?? this.slot,
      imageUrl: imageUrl ?? this.imageUrl,
      Banner_img: Banner_img ?? this.Banner_img,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      activeDiscounts: activeDiscounts ?? this.activeDiscounts,
      cuisineType: cuisineType ?? this.cuisineType,
      reviewCount: reviewCount ?? this.reviewCount,
      isBusy: isBusy ?? this.isBusy,
      distance: distance ?? this.distance,
      isManuallyOpen: isManuallyOpen ?? this.isManuallyOpen,
      category: category ?? this.category, // Add category to copyWith
    );
  }

  // Enhance the isCurrentlyOpen method to be more accurate
  bool isCurrentlyOpen() {
    if (!isManuallyOpen) return false; // If manually closed, return false
    if (!isOpen) return false; // If globally closed, return false

    // If we're in manual mode, just return the isOpen value
    if (isManuallyOpen) return isOpen;

    // For schedule-based determination:
    if (openTime == null || closeTime == null) {
      return false; // If no times set, assume closed
    }

    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final openMinutes = openTime!.hour * 60 + openTime!.minute;
    final closeMinutes = closeTime!.hour * 60 + closeTime!.minute;

    // Handle normal case where open time is before close time
    if (closeMinutes > openMinutes) {
      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
    } else {
      // Handle cases where closing time is on the next day (e.g., 22:00 - 02:00)
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    }
  }

  // Helper method to get reason for closure
  String getClosedReason() {
    if (!isManuallyOpen) return "Manually closed by vendor";
    if (_scheduleInfo != null && _scheduleInfo!['is_default'] == true) {
      // Using default schedule
      if (_scheduleInfo!['reason'] != null) {
        return _scheduleInfo!['reason'] as String;
      }

      // Check if it's outside business hours
      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      if (_scheduleInfo!.containsKey('open_time') &&
          currentTime.compareTo(_scheduleInfo!['open_time'] as String) < 0) {
        return "Opens at ${_formatTimeString(_scheduleInfo!['open_time'] as String)}";
      } else {
        return "Closed for the day";
      }
    }

    // Original logic for custom schedules
    if (!isOpen) return "Closed per schedule";
    if (openTime != null && closeTime != null) {
      final now = TimeOfDay.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final openMinutes = openTime!.hour * 60 + openTime!.minute;

      if (currentMinutes < openMinutes) {
        return "Opens at ${_formatTimeOfDay(openTime!)}";
      } else {
        return "Closed for the day";
      }
    }
    return "Closed";
  }

  // Helper method to format TimeOfDay
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  // Helper format time string for default schedule
  String _formatTimeString(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';

      hour = hour > 12 ? hour - 12 : hour;
      hour = hour == 0 ? 12 : hour;

      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  // Improve the hasActivePromotions method
  bool hasActivePromotions() {
    // Check if activeDiscounts is loaded and has items
    if (activeDiscounts != null && activeDiscounts!.isNotEmpty) {
      print('Stan has ${activeDiscounts!.length} active discounts');
      return true;
    }

    // If we haven't checked for Schedule info yet, return false
    if (_scheduleInfo == null) {
      print('Stan schedule info not loaded yet, defaulting to no promotions');
      return false;
    }

    // Check if there are any discounts in the scheduleInfo
    final hasDiscounts = _scheduleInfo!['has_promotions'] == true;
    print('Stan promotion check from scheduleInfo: $hasDiscounts');
    return hasDiscounts;
  }
}
