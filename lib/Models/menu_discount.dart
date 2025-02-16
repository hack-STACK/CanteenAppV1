class MenuDiscount {
  final int id;
  final int menuId;
  final int discountId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MenuDiscount({
    required this.id,
    required this.menuId,
    required this.discountId,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_menu': menuId,
        'id_discount': discountId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  factory MenuDiscount.fromJson(Map<String, dynamic> json) => MenuDiscount(
        id: json['id'],
        menuId: json['id_menu'],
        discountId: json['id_discount'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_menu': menuId,
      'id_discount': discountId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static MenuDiscount fromMap(Map<String, dynamic> map) {
    return MenuDiscount(
      id: map['id'],
      menuId: map['id_menu'],
      discountId: map['id_discount'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}
