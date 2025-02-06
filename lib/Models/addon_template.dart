import 'package:kantin/Models/menus_addon.dart'; // Add this import

class AddonTemplate {
  final int? id;
  final String addonName;
  final double price;
  final bool isRequired;
  final String? description;
  final int useCount; // Track how many times this add-on is used

  AddonTemplate({
    this.id,
    required this.addonName,
    required this.price,
    this.isRequired = false,
    this.description,
    this.useCount = 0,
  });

  factory AddonTemplate.fromMap(Map<String, dynamic> map) {
    return AddonTemplate(
      id: map['id'] as int?,
      addonName: map['addon_name'] as String,
      price: (map['price'] as num).toDouble(),
      isRequired: map['is_required'] as bool? ?? false,
      description: map['description'] as String?,
      useCount: map['use_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'addon_name': addonName,
      'price': price,
      'is_required': isRequired,
      'description': description,
      'use_count': useCount,
    };
  }

  // Convert to FoodAddon for a specific menu
  FoodAddon toFoodAddon(int menuId) {
    return FoodAddon(
      menuId: menuId,
      addonName: addonName,
      price: price,
      isRequired: isRequired,
      description: description,
    );
  }
}
