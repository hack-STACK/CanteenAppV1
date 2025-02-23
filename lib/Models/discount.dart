class Discount {
  final int id;
  final String discountName;
  final double discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String type;
  bool isActive;
  final int? stallId;

  static const List<String> validTypes = ['mainPrice', 'addons', 'both'];

  Discount({
    required this.id,
    required this.discountName,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? type,
    bool? isActive,
    this.stallId,
  })  : createdAt =
            createdAt ?? DateTime.now().toUtc(), // Ensure UTC timestamps
        updatedAt = updatedAt ?? DateTime.now().toUtc(),
        type = type ?? 'mainPrice',
        isActive = isActive ?? true {
    // Validate type against allowed values
    if (!validTypes.contains(this.type)) {
      throw ArgumentError(
          'Invalid discount type: ${this.type}. Must be one of: $validTypes');
    }
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    final dynamic rawPercentage = map['discount_percentage'];
    final double percentage = rawPercentage is int
        ? rawPercentage.toDouble()
        : rawPercentage as double;

    return Discount(
      id: map['id'] as int,
      discountName: map['discount_name'] as String,
      discountPercentage: percentage,
      startDate: DateTime.parse(map['start_date'] as String).toLocal(),
      endDate: DateTime.parse(map['end_date'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      type: map['type'] as String? ?? 'mainPrice',
      isActive: map['is_active'] as bool? ?? true,
      stallId: map['stall_id'] as int?,
    );
  }

  factory Discount.fromJson(Map<String, dynamic> json) {
    // Reuse existing fromMap logic since JSON structure matches
    return Discount.fromMap(json);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id, // Only include id if it's not 0 (new record)
      'discount_name': discountName,
      'discount_percentage': discountPercentage,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
      'type': type,
      'is_active': isActive,
      'stall_id': stallId,
      // Don't include created_at and updated_at as they're handled by the database
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
    int? stallId,
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
      stallId: stallId ?? this.stallId,
    );
  }
}
