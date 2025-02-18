class MenuDiscount {
  final int id;
  final int menuId;
  final int discountId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuDiscount({
    required this.id,
    required this.menuId,
    required this.discountId,
    required this.isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Add fromMap and toMap methods
  factory MenuDiscount.fromMap(Map<String, dynamic> map) {
    return MenuDiscount(
      id: map['id'] as int,
      menuId: map['menu_id'] as int,
      discountId: map['discount_id'] as int,
      isActive: map['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'menu_id': menuId,
      'discount_id': discountId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MenuDiscount copyWith({
    int? id,
    int? menuId,
    int? discountId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuDiscount(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      discountId: discountId ?? this.discountId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
