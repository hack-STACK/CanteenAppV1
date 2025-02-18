import 'package:kantin/Models/discount.dart';

class MenuDiscount {
  final int id;
  final int menuId;
  final int discountId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Discount? discount; // Add this to store joined discount data

  MenuDiscount({
    required this.id,
    required this.menuId,
    required this.discountId,
    required this.isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.discount,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory MenuDiscount.fromJson(Map<String, dynamic> json) {
    return MenuDiscount(
      id: json['id'] as int,
      menuId: json['id_menu'] as int, // Updated field name
      discountId: json['id_discount'] as int, // Updated field name
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      discount: json['discount'] != null ? Discount.fromMap(json['discount']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_menu': menuId, // Updated field name
      'id_discount': discountId, // Updated field name
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Add these methods
  factory MenuDiscount.fromMap(Map<String, dynamic> map) {
    return MenuDiscount(
      id: map['id'] as int,
      menuId: map['id_menu'] as int,
      discountId: map['id_discount'] as int,
      isActive: map['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      discount: map['discount'] != null ? Discount.fromMap(map['discount']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return toJson(); // Reuse existing toJson method
  }

  MenuDiscount copyWith({
    int? id,
    int? menuId,
    int? discountId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Discount? discount,
  }) {
    return MenuDiscount(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      discountId: discountId ?? this.discountId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      discount: discount ?? this.discount,
    );
  }
}
