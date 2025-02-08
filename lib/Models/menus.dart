import 'package:kantin/Models/menus_addon.dart';

class Menu {
  static const validTypes = {'food', 'drink'};

  final int? id;
  final String foodName;
  final double price;
  final String type; // "food" or "drink"
  final String photo;
  final String description;
  final int stallId;
  final List<FoodAddon> addons; // New field for add-ons

  Menu({
    required this.id,
    required this.foodName,
    required this.price,
    required String type, // Add validation here
    required this.photo,
    required this.description,
    required this.stallId,
    this.addons = const [], // Default to empty list
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
      type: json['type'],
      photo: json['photo'],
      description: json['description'],
      stallId: json['stall_id'],
      addons: parsedAddons,
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
      // Remove 'addons' from the main JSON data
    };

    if (!excludeId && id != null) {
      data['id'] = id!;
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
}
