import 'package:kantin/Models/menus_addon.dart';

class Menu {
  static const validTypes = {'food', 'drink'};
  static const defaultRating = 0.0;
  static const defaultTotalRatings = 0;

  final int? id;
  final String foodName;
  final double price;
  final String type;
  final String? photo;
  final String? description;
  final int stallId;
  final bool isAvailable;
  final String? category;
  final double rating;
  final int totalRatings;
  final List<FoodAddon> addons; // Add this field

  Menu({
    this.id,
    required this.foodName,
    required this.price,
    required String type,
    this.photo,
    this.description,
    required this.stallId,
    this.isAvailable = true,
    this.category,
    double? rating,
    int? totalRatings,
    List<FoodAddon>? addons, // Add to constructor
  })  : type = type.toLowerCase(),
        rating = rating ?? defaultRating,
        totalRatings = totalRatings ?? defaultTotalRatings,
        addons = addons ?? []; // Initialize addons list

  factory Menu.fromMap(Map<String, dynamic> map) {
    return Menu(
      id: map['id'] as int?,
      foodName: map['food_name'] as String,
      price: (map['price'] as num).toDouble(),
      type: map['type'] as String,
      photo: map['photo'] as String?,
      description: map['description'] as String?,
      stallId: map['stall_id'] as int,
      isAvailable: map['is_available'] as bool? ?? true,
      category: map['category'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? defaultRating,
      totalRatings: map['total_ratings'] as int? ?? defaultTotalRatings,
      addons: [], // Initialize empty addons list
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'food_name': foodName,
      'price': price,
      'type': type,
      'photo': photo,
      'description': description,
      'stall_id': stallId,
      'is_available': isAvailable,
      'category': category,
      'rating': rating,
      'total_ratings': totalRatings,
    };
  }

  // Add toJson method
  Map<String, dynamic> toJson({bool excludeId = false}) {
    final map = {
      'food_name': foodName,
      'price': price,
      'type': type,
      'photo': photo,
      'description': description,
      'stall_id': stallId,
      'is_available': isAvailable,
      'category': category,
      'rating': rating,
      'total_ratings': totalRatings,
    };

    if (!excludeId && id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Update fromJson factory constructor with better null handling
  factory Menu.fromJson(Map<String, dynamic> json) {
    try {
      final stallData = json['stall'] as Map<String, dynamic>?;
      return Menu(
        id: json['id'] as int?,
        foodName: json['food_name'] as String? ?? 'Unknown Item',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        type: (json['type'] as String?) ?? 'food',
        photo: json['photo'] as String?,
        description: json['description'] as String?,
        stallId: stallData?['id'] as int? ?? 0,
        isAvailable: json['is_available'] as bool? ?? true,
        category: json['category'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? defaultRating,
        totalRatings: json['total_ratings'] as int? ?? defaultTotalRatings,
        addons: [], // Initialize empty addons list
      );
    } catch (e) {
      print('Error creating Menu from JSON: $e');
      print('JSON data: $json');
      // Return a default menu item in case of error
      return Menu(
        id: 0,
        foodName: 'Error Loading Item',
        price: 0,
        type: 'food',
        stallId: 0,
        isAvailable: false,
      );
    }
  }

  Menu copyWith({
    int? id,
    String? foodName,
    double? price,
    String? type,
    String? photo,
    String? description,
    int? stallId,
    bool? isAvailable,
    String? category,
    double? rating,
    int? totalRatings,
    List<FoodAddon>? addons,
  }) {
    return Menu(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      price: price ?? this.price,
      type: type ?? this.type,
      photo: photo ?? this.photo,
      description: description ?? this.description,
      stallId: stallId ?? this.stallId,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      addons: addons ?? this.addons,
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);
  bool get hasRating => rating > 0 && totalRatings > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Menu &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          foodName == other.foodName;

  @override
  int get hashCode => id.hashCode ^ foodName.hashCode;

  @override
  String toString() {
    return 'Menu{id: $id, foodName: $foodName, price: $price, type: $type, category: $category, rating: $rating}';
  }
}
