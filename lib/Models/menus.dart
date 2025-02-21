import 'package:kantin/Models/menus_addon.dart';

class Menu {
  static const validTypes = {'food', 'drink'};
  static const defaultRating = 0.0;
  static const defaultTotalRatings = 0;

  final int id;
  final String foodName;
  final double price;
  final String type; // Should be "food" or "drink"
  final String? photo;
  final String? description;
  final int stallId; // Ensure this is non-nullable
  final bool isAvailable;
  final String? category;
  final double rating;
  final int totalRatings;
  final List<FoodAddon> addons; // Add this field
  final bool isPopular;
  final bool isRecommended;
  final int reviewCount;
  final bool isVegetarian;
  final bool isSpicy;
  final List<String> tags;
  final int? preparationTime;
  final double? originalPrice;

  Menu({
    required this.id,
    required this.foodName,
    required this.price,
    required String type,
    this.photo,
    this.description,
    required this.stallId, // Make stallId required
    this.isAvailable = true,
    this.category,
    double? rating,
    int? totalRatings,
    List<FoodAddon>? addons, // Add to constructor
    this.isPopular = false,
    this.isRecommended = false,
    this.reviewCount = 0,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.tags = const [],
    this.preparationTime,
    this.originalPrice,
  })  : type = type.toLowerCase(),
        assert(type.toLowerCase() == 'food' || type.toLowerCase() == 'drink'),
        rating = rating ?? defaultRating,
        totalRatings = totalRatings ?? defaultTotalRatings,
        addons = addons ?? []; // Initialize addons list

  factory Menu.fromMap(Map<String, dynamic> map) {
    final type = (map['type'] as String?)?.toLowerCase() ?? 'food';
    if (type != 'food' && type != 'drink') {
      throw FormatException(
          'Invalid menu type: $type. Must be "food" or "drink"');
    }
    return Menu(
      id: map['id'] as int,
      foodName: map['food_name'] as String,
      price: (map['price'] as num).toDouble(),
      type: type,
      photo: map['photo'] as String?,
      description: map['description'] as String?,
      stallId: map['stall_id'] as int,
      isAvailable: map['is_available'] as bool? ?? true,
      category: map['category'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? defaultRating,
      totalRatings: map['total_ratings'] as int? ?? defaultTotalRatings,
      addons: [], // Initialize empty addons list
      isPopular: map['is_popular'] ?? false,
      isRecommended: map['is_recommended'] ?? false,
      reviewCount: map['review_count'] ?? 0,
      isVegetarian: map['is_vegetarian'] ?? false,
      isSpicy: map['is_spicy'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      'is_popular': isPopular,
      'is_recommended': isRecommended,
      'review_count': reviewCount,
      'is_vegetarian': isVegetarian,
      'is_spicy': isSpicy,
      'tags': tags,
      'preparation_time': preparationTime,
      'original_price': originalPrice,
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
      'is_popular': isPopular,
      'is_recommended': isRecommended,
      'review_count': reviewCount,
      'is_vegetarian': isVegetarian,
      'is_spicy': isSpicy,
      'tags': tags,
      'preparation_time': preparationTime,
      'original_price': originalPrice,
    };

    if (!excludeId) {
      map['id'] = id;
    }

    return map;
  }

  // Update fromJson factory constructor with better null handling
  factory Menu.fromJson(Map<String, dynamic> json) {
    // Ensure stallId is properly extracted and validated
    final stallId = json['stall_id'] ?? json['stallId'];
    if (stallId == null || stallId == 0) {
      throw Exception('Invalid or missing stall ID in menu data');
    }

    try {
      final stallData = json['stall'] as Map<String, dynamic>?;
      final type = (json['type'] as String?)?.toLowerCase() ?? 'food';
      if (type != 'food' && type != 'drink') {
        throw FormatException(
            'Invalid menu type: $type. Must be "food" or "drink"');
      }
      return Menu(
        id: json['id'] as int,
        foodName: json['food_name'] as String? ?? 'Unknown Item',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        type: type,
        photo: json['photo'] as String?,
        description: json['description'] as String?,
        stallId: stallId,
        isAvailable: json['is_available'] as bool? ?? true,
        category: json['category'] as String?,
        rating: (json['rating'] as num?)?.toDouble() ?? defaultRating,
        totalRatings: json['total_ratings'] as int? ?? defaultTotalRatings,
        addons: (json['addons'] as List<dynamic>?)
                ?.map((addon) => FoodAddon.fromJson(addon))
                .toList() ??
            [], // Initialize empty addons list
        isPopular: json['is_popular'] ?? false,
        isRecommended: json['is_recommended'] ?? false,
        reviewCount: json['review_count'] ?? 0,
        isVegetarian: json['is_vegetarian'] ?? false,
        isSpicy: json['is_spicy'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
        preparationTime: json['preparation_time'] as int?,
        originalPrice: (json['original_price'] as num?)?.toDouble(),
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
    bool? isPopular,
    bool? isRecommended,
    int? reviewCount,
    bool? isVegetarian,
    bool? isSpicy,
    List<String>? tags,
    int? preparationTime,
    double? originalPrice,
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
      isPopular: isPopular ?? this.isPopular,
      isRecommended: isRecommended ?? this.isRecommended,
      reviewCount: reviewCount ?? this.reviewCount,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isSpicy: isSpicy ?? this.isSpicy,
      tags: tags ?? this.tags,
      preparationTime: preparationTime ?? this.preparationTime,
      originalPrice: originalPrice ?? this.originalPrice,
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
