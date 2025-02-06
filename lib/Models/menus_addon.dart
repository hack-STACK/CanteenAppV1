class FoodAddon {
  final int? id;
  final int menuId;
  final String addonName;
  final double price;
  final bool isRequired;
  final String? description;

  FoodAddon({
    this.id,
    required this.menuId,
    required this.addonName,
    required this.price,
    this.isRequired = false,
    this.description,
  });

  // Convert from JSON (fetch from Supabase)
  factory FoodAddon.fromJson(Map<String, dynamic> json) {
    return FoodAddon(
      id: json['id'],
      menuId: json['menu_id'],
      addonName: json['addon_name'],
      price: json['price'].toDouble(),
      isRequired: json['is_required'] ?? false,
      description: json['description'],
    );
  }

  // Convert to JSON (insert to Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_id': menuId,
      'addon_name': addonName,
      'price': price,
      'is_required': isRequired,
      'description': description,
    };
  }
}