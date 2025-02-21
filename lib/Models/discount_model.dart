class Discount {
  final int id;
  final String discountName;
  final double discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final bool isActive;
  final int? stallId;

  Discount({
    required this.id,
    required this.discountName,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.isActive,
    this.stallId,
  });

  factory Discount.fromMap(Map<String, dynamic> map) {
    try {
      return Discount(
        id: map['id'] as int,
        discountName: map['discount_name'] as String? ?? '',
        discountPercentage: map['discount_percentage'] is int
            ? (map['discount_percentage'] as int).toDouble()
            : (map['discount_percentage'] as num).toDouble(),
        startDate: DateTime.parse(map['start_date']),
        endDate: DateTime.parse(map['end_date']),
        type: map['type'] as String? ?? 'mainPrice',
        isActive: map['is_active'] as bool? ?? false,
        stallId: map['stall_id'] as int?,
      );
    } catch (e) {
      print('Error creating Discount from map: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'discount_name': discountName,
      'discount_percentage': discountPercentage,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'type': type,
      'is_active': isActive,
      'stall_id': stallId,
    };
  }
}
