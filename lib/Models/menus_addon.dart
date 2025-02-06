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
    this.isRequired = false, // Default to false as per DB schema
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'menu_id': menuId,
      'addon_name': addonName,
      'price': price,
      'is_required': isRequired,
      'description': description,
    };
  }

  factory FoodAddon.fromMap(Map<String, dynamic> map) {
    return FoodAddon(
      id: map['id'] as int?,
      menuId: map['menu_id'] as int,
      addonName: map['addon_name'] as String,
      price: (map['price'] as num).toDouble(),
      isRequired: map['is_required'] as bool? ?? false,
      description: map['description'] as String?,
    );
  }

  // These methods can just use toMap/fromMap since the structure is the same
  factory FoodAddon.fromJson(Map<String, dynamic> json) =>
      FoodAddon.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
