import 'package:kantin/Models/menus_addon.dart';

class Menu {
  static const validTypes = {'food', 'drink'};

  final int? id; // Make id nullable
  final String foodName;
  final double price;
  final String type; // "food" or "drink"
  final String? photo;
  final String description;
  final int stallId;
  final List<FoodAddon> addons; // New field for add-ons
  bool isAvailable;
  String? category;

  Menu({
    this.id, // Make id optional
    required this.foodName,
    required this.price,
    required String type,
    this.photo,
    required this.description,
    required this.stallId,
    this.addons = const [], // Default to empty list
    this.isAvailable = true,
    this.category,
  }) : type = type.toLowerCase() {
    // Normalize type to lowercase
    if (!validTypes.contains(this.type)) {
      throw ArgumentError(
          'Invalid menu type. Must be either "food" or "drink"');
    }
    if (price < 0) {
      throw ArgumentError('Price must be greater than or equal to 0');
    }
    if (foodName.isEmpty) {
      throw ArgumentError('Food name cannot be empty');
    }
    if (foodName.length > 100) {
      throw ArgumentError('Food name cannot exceed 100 characters');
    }
  }

  // Convert from JSON (fetch from Supabase)
  factory Menu.fromJson(Map<String, dynamic> json) {
    // Handle the addons array from JSON
    List<FoodAddon> parsedAddons = [];
    if (json['addons'] != null) {
      parsedAddons = (json['addons'] as List)
          .map((addonJson) => FoodAddon.fromJson(addonJson))
          .toList();
    }

    return Menu(
      id: json['id'],
      foodName: json['food_name'],
      price: json['price'].toDouble(),
      type: json['type'] as String,
      photo: json['photo'],
      description: json['description'] ?? '',
      stallId: json['stall_id'],
      addons: parsedAddons,
      isAvailable: json['is_available'] ?? true, // Updated field name
      category: json['category'],
    );
  }

  // Convert to JSON (insert to Supabase)
  Map<String, dynamic> toJson({bool excludeId = false}) {
    // Validate before converting to JSON
    if (!validTypes.contains(type)) {
      throw ArgumentError('Invalid menu type: $type');
    }

    final data = {
      'food_name': foodName,
      'price': price,
      'type': type,
      'photo': photo,
      'description': description,
      'stall_id': stallId,
      'is_available': isAvailable, // Updated field name
      'category': category,
      // Remove 'addons' from the main JSON data
    };

    if (!excludeId && id != null) {
      data['id'] = id;
    }

    return data;
  }

  // Add a new method to get the complete JSON including addons
  Map<String, dynamic> toCompleteJson({bool excludeId = false}) {
    final data = toJson(excludeId: excludeId);
    data['addons'] = addons.map((addon) => addon.toJson()).toList();
    return data;
  }

  // Create a copy of Menu with modifications
  Menu copyWith({
    int? id,
    String? foodName,
    double? price,
    String? type,
    String? photo,
    String? description,
    int? stallId,
    List<FoodAddon>? addons,
    bool? isAvailable,
    String? category,
  }) {
    return Menu(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      price: price ?? this.price,
      type: type ?? this.type,
      photo: photo ?? this.photo,
      description: description ?? this.description,
      stallId: stallId ?? this.stallId,
      addons: addons ?? this.addons,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
    );
  }

  // Cache computed values
  double? _totalPrice;

  // Computed property for total price including required addons
  double get totalPrice {
    _totalPrice ??= price +
        addons
            .where((addon) => addon.isRequired)
            .fold(0.0, (sum, addon) => sum + addon.price);
    return _totalPrice!;
  }

  // Override == and hashCode for better comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Menu &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          foodName == other.foodName;

  @override
  int get hashCode => id.hashCode ^ foodName.hashCode;

  factory Menu.fromMap(Map<String, dynamic> map) {
    print('Processing menu map: $map');
    return Menu(
      id: map['id'] as int?, // Handle nullable id
      foodName: map['food_name'] as String,
      price: (map['price'] as num).toDouble(),
      type: map['type'] as String,
      photo: map['photo'] as String?,
      description: map['description'] as String? ?? '',
      stallId: map['stall_id'] as int,
      isAvailable: map['is_available'] as bool? ?? true,
      category: map['category'] as String?,
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
    };
  }

  @override
  String toString() {
    return 'Menu{id: $id, foodName: $foodName, price: $price, type: $type, photo: $photo, description: $description, stallId: $stallId}';
  }
}
