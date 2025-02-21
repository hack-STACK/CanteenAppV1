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
  final bool isOpen; // New field
  final TimeOfDay? openTime; // New field
  final TimeOfDay? closeTime; // New field
  final List<Discount>? activeDiscounts;
  final String? cuisineType;
  final int reviewCount;
  final bool isBusy;
  final double? distance;

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
  });

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
    );
  }

  // Add method to check if stall is currently open
  bool isCurrentlyOpen() {
    if (!isOpen) return false;
    if (openTime == null || closeTime == null) return true;

    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final openMinutes = openTime!.hour * 60 + openTime!.minute;
    final closeMinutes = closeTime!.hour * 60 + closeTime!.minute;

    if (closeMinutes > openMinutes) {
      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
    } else {
      // Handles cases where closing time is on the next day
      return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
    }
  }

  bool hasActivePromotions() {
    return activeDiscounts != null && activeDiscounts!.isNotEmpty;
  }
}
