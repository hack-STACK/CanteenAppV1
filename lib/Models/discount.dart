class Discount {
  final int id;
  final String discountName;
  final double discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String type;
  bool isActive; // Changed from final to non-final

  Discount({
    required this.id,
    required this.discountName,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.type = 'mainPrice',
    this.isActive = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Discount.fromMap(Map<String, dynamic> map) {
    final dynamic rawPercentage = map['discount_percentage'];
    final double percentage = rawPercentage is int
        ? rawPercentage.toDouble()
        : rawPercentage as double;

    return Discount(
      id: map['id'] as int,
      discountName: map['discount_name'] as String,
      discountPercentage: percentage,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      type: map['type'] as String? ?? 'mainPrice',
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discount_name': discountName,
      'discount_percentage': discountPercentage,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'type': type,
      'is_active': isActive,
    };
  }

  Discount copyWith({
    int? id,
    String? discountName,
    double? discountPercentage,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    bool? isActive,
  }) {
    return Discount(
      id: id ?? this.id,
      discountName: discountName ?? this.discountName,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }

  static List<String> get validTypes => ['mainPrice', 'addons', 'both'];
}
