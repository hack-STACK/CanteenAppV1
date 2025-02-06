import 'package:kantin/Models/menus_addon.dart';

class Menu {
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
    required this.type,
    required this.photo,
    required this.description,
    required this.stallId,
    this.addons = const [], // Default to empty list
  });

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
    final data = {
      'food_name': foodName,
      'price': price,
      'type': type,
      'photo': photo,
      'description': description,
      'stall_id': stallId,
      'addons': addons.map((addon) => addon.toJson()).toList(),
    };

    if (!excludeId && id != null) {
      data['id'] = id!; // Include only if updating
    }

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
}