import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  double? originalPrice; // Remove final
  double? discountedPrice; // Remove final

  double? _discountedPrice;
  double? _discountPercentage;
  bool _hasCheckedDiscount = false;
  List<Discount>? _discounts;

  // Cache for discount calculations
  bool _discountChecked = false;
  double? _cachedEffectivePrice;
  bool? _cachedHasDiscount;
  double? _cachedDiscountPercent;

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
    this.discountedPrice,
  })  : type = type.toLowerCase(),
        assert(type.toLowerCase() == 'food' || type.toLowerCase() == 'drink'),
        rating = rating ?? defaultRating,
        totalRatings = totalRatings ?? defaultTotalRatings,
        addons = addons ?? []; // Initialize addons list

  factory Menu.fromMap(Map<String, dynamic> map) {
    print('\n=== Creating Menu from Map ===');
    print('Raw map data: $map');

    final basePrice = (map['price'] as num).toDouble();
    double? discountPrice;
    double? discountPercentage;

    try {
      // Process menu_discounts with null safety
      if (map['menu_discounts'] != null && map['menu_discounts'] is List) {
        final discounts = map['menu_discounts'] as List;

        for (final discount in discounts) {
          if (discount == null) continue;

          // Safely check if discount is active
          final isActive = discount['is_active'] == true;
          if (!isActive) continue;

          // First try to get effective_price directly
          if (discount['effective_price'] != null) {
            final effectivePrice =
                (discount['effective_price'] as num?)?.toDouble();
            if (effectivePrice != null && effectivePrice > 0) {
              discountPrice = effectivePrice;
              // Calculate percentage from effective price
              discountPercentage =
                  ((basePrice - effectivePrice) / basePrice * 100)
                      .roundToDouble();
              break;
            }
          }

          // Try to get discount_percentage if no effective price
          if (discount['discount_percentage'] != null) {
            final percentage =
                (discount['discount_percentage'] as num?)?.toDouble();
            if (percentage != null && percentage > 0) {
              discountPercentage = percentage;
              discountPrice = basePrice * (1 - (percentage / 100));
              break;
            }
          }

          // Try to get from nested discount object
          final discountObj = discount['discount'];
          if (discountObj != null && discountObj is Map<String, dynamic>) {
            final percentage =
                (discountObj['discount_percentage'] as num?)?.toDouble();
            if (percentage != null && percentage > 0) {
              discountPercentage = percentage;
              discountPrice = basePrice * (1 - (percentage / 100));
              break;
            }
          }
        }
      }

      print('Discount calculation results:');
      print('Original price: $basePrice');
      print('Discount price: $discountPrice');
      print('Discount percentage: $discountPercentage%');
    } catch (e) {
      print('Error processing discount: $e');
      print('Discount data: ${map['menu_discounts']}');
      discountPrice = null;
      discountPercentage = null;
    }

    // Create menu with calculated discount
    return Menu(
      id: map['id'] as int,
      foodName: map['food_name'] as String,
      price: basePrice,
      type: (map['type'] as String?)?.toLowerCase() ?? 'food',
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
      discountedPrice: discountPrice,
      originalPrice: basePrice,
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
      'discounted_price': discountedPrice, // Add this line
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
    try {
      print('\n========= Menu JSON Debug =========');

      final basePrice = (json['price'] as num?)?.toDouble() ?? 0.0;
      print('Base Price: $basePrice');

      // Get discount information
      final discounts = json['menu_discounts'] as List<dynamic>?;
      double? discountedPrice;

      if (discounts != null && discounts.isNotEmpty) {
        print('Found ${discounts.length} discounts');

        final activeDiscount = discounts.firstWhere(
          (d) {
            final isActive = d['is_active'] == true;
            final hasDiscount = d['discounts'] != null;
            final isDiscountActive = d['discounts']?['is_active'] == true;

            print('Discount Debug:');
            print('Is Active: $isActive');
            print('Has Discount: $hasDiscount');
            print('Is Discount Active: $isDiscountActive');

            return isActive && hasDiscount && isDiscountActive;
          },
          orElse: () => null,
        );

        if (activeDiscount != null) {
          final discountPercentage =
              (activeDiscount['discounts']['discount_percentage'] as num)
                  .toDouble();
          discountedPrice = basePrice * (1 - (discountPercentage / 100));

          print('Applied Discount:');
          print('Percentage: $discountPercentage%');
          print('Original Price: $basePrice');
          print('Discounted Price: $discountedPrice');
        }
      }

      // Handle different possible stall ID field names
      final stallId = json['stall_id'] ??
          json['stallId'] ??
          (json['stall'] as Map<String, dynamic>?)?['id'] ??
          0;

      // If no valid stall ID is found, use a default value instead of throwing an error
      if (stallId == 0) {
        print(
            'Warning: Using default stall ID for menu: ${json['food_name'] ?? 'Unknown'}');
      }

      final type = (json['type'] as String?)?.toLowerCase() ?? 'food';
      if (type != 'food' && type != 'drink') {
        throw FormatException(
            'Invalid menu type: $type. Must be "food" or "drink"');
      }

      final menu = Menu(
        id: json['id'] ?? 0,
        stallId: stallId, // Use the resolved stallId
        foodName: json['food_name'] ?? json['foodName'] ?? 'Unknown Item',
        price: basePrice,
        type: type,
        photo: json['photo'],
        description: json['description'] ?? '',
        isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
        category: json['category'] ?? '',
        rating:
            json['rating'] != null ? (json['rating'] as num).toDouble() : null,
        totalRatings: json['total_ratings'] ?? json['totalRatings'] ?? 0,
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
        originalPrice: basePrice,
        discountedPrice: discountedPrice,
      );

      print('Final Menu State:');
      print('Has Discount: ${menu.hasDiscount}');
      print('Effective Price: ${menu.effectivePrice}');
      print('Discount Amount: ${menu.discountAmount}');
      print('===============================\n');

      return menu;
    } catch (e, stack) {
      print('Error in Menu.fromJson: $e\n$stack');
      // Return a valid menu item instead of throwing
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
    double? discountedPrice, // Add this parameter
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
      discountedPrice: discountedPrice ?? this.discountedPrice, // Add this line
    );
  }

  String get formattedRating => rating.toStringAsFixed(1);
  bool get hasRating => rating > 0 && totalRatings > 0;

  // Update effectivePrice getter to use caching
  double get effectivePrice {
    if (!_discountChecked) {
      _calculateDiscountValues();
    }
    return _cachedEffectivePrice ?? price;
  }

  // Update hasDiscount getter to use caching
  bool get hasDiscount {
    if (!_discountChecked) {
      _calculateDiscountValues();
    }
    return _cachedHasDiscount ?? false;
  }

  // Update discountPercent getter to use caching
  double get discountPercent {
    if (!_discountChecked) {
      _calculateDiscountValues();
    }
    return _cachedDiscountPercent ?? 0.0;
  }

  // Private method to calculate all discount-related values at once
  void _calculateDiscountValues() {
    try {
      final hasValidDiscount = _discountedPrice != null &&
          _discountedPrice! > 0 &&
          _discountedPrice! < price &&
          _discountPercentage != null &&
          _discountPercentage! > 0;

      _cachedHasDiscount = hasValidDiscount;
      _cachedEffectivePrice = hasValidDiscount ? _discountedPrice! : price;
      _cachedDiscountPercent = hasValidDiscount ? _discountPercentage! : 0.0;

      print('\n=== Discount Calculation ===');
      print('Original price: $price');
      print('Discounted price: $_discountedPrice');
      print('Discount percentage: $_discountPercentage');
      print('Has discount: $_cachedHasDiscount');
      print('Effective price: $_cachedEffectivePrice');
      print('Cache discount percent: $_cachedDiscountPercent%');
      print('==========================\n');
    } catch (e) {
      print('Error in discount calculation: $e');
      _cachedHasDiscount = false;
      _cachedEffectivePrice = price;
      _cachedDiscountPercent = 0.0;
    }

    _discountChecked = true;
  }

  // Update discountAmount getter to use cached values
  double get discountAmount {
    if (!_discountChecked) {
      _calculateDiscountValues();
    }
    return hasDiscount ? price - effectivePrice : 0.0;
  }

  // Update fetchDiscount method
  Future<void> fetchDiscount() async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now().toUtc().toIso8601String();

      print('Fetching discounts for menu $id at $now');

      final response = await supabase
          .from('menu_discounts')
          .select('''
            *,
            discounts:id_discount (
              id,
              discount_name,
              discount_percentage,
              start_date,
              end_date,
              is_active,
              type
            )
          ''')
          .eq('id_menu', id)
          .eq('is_active', true)
          .eq('discounts.is_active', true)
          .lte('discounts.start_date', now)
          .gte('discounts.end_date', now)
          .order('discount_percentage', ascending: false)
          .limit(1);

      print('Raw discount response: $response');

      if ((response as List).isNotEmpty) {
        final discountData = response.first;
        final discountInfo = discountData['discounts'];

        if (discountInfo != null && discountInfo['is_active'] == true) {
          // Get discount percentage from the discount record
          final percentage =
              (discountInfo['discount_percentage'] as num).toDouble();

          // Calculate discounted price
          _discountedPrice = price * (1 - (percentage / 100));
          _discountPercentage = percentage;

          print('Found active discount:');
          print('Discount Info: $discountInfo');
          print('Percentage: $_discountPercentage%');
          print('Original Price: $price');
          print('Calculated Discounted Price: $_discountedPrice');

          // Don't override with effective_price from menu_discounts
          discountedPrice = _discountedPrice;
          originalPrice = price;
        }
      }

      _hasCheckedDiscount = true;
      _discountChecked = false;
      _calculateDiscountValues();
    } catch (e, stack) {
      print('Error fetching discount: $e');
      print('Stack trace: $stack');
    }
  }

  // Clean up other redundant getters
  double get discountPercentage => discountPercent;

  List<Discount> get discounts {
    if (_discounts == null) {
      // If discounts haven't been fetched yet, return empty list
      return [];
    }
    return _discounts!;
  }

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
    return 'Menu{id: $id, name: $foodName, price: $price, type: $type, isAvailable: $isAvailable}';
  }
} // Add closing brace for the class
