class FoodAddon {
  final int? id;
  final int menuId;
  final String addonName;
  final double price;
  final bool isRequired;
  final int stockQuantity;
  final bool isAvailable;
  final String? description;

  FoodAddon({
    this.id,
    required this.menuId,
    required this.addonName,
    required this.price,
    this.isRequired = false,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.description,
  }) {
    if (price < 0) {
      throw ArgumentError('Price must be non-negative');
    }
    if (addonName.isEmpty) {
      throw ArgumentError('Addon name cannot be empty');
    }
    if (addonName.length > 100) {
      throw ArgumentError('Addon name cannot exceed 100 characters');
    }
    if (stockQuantity < 0) {
      throw ArgumentError('Stock quantity cannot be negative');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'menu_id': menuId,
      'addon_name': addonName,
      'price': price,
      'is_required': isRequired,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'Description': description, // Note the capital D to match schema
    };
  }

  factory FoodAddon.fromMap(Map<String, dynamic> map) {
    return FoodAddon(
      id: map['id']?.toInt(),
      menuId: map['menu_id']?.toInt() ?? 0,
      addonName: map['addon_name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isRequired: map['is_required'] ?? false,
      stockQuantity: map['stock_quantity']?.toInt() ?? 0,
      isAvailable: map['is_available'] ?? true,
      description: map['Description'] as String?, // Note the capital D to match schema
    );
  }

  factory FoodAddon.fromJson(Map<String, dynamic> json) =>
      FoodAddon.fromMap(json);

  Map<String, dynamic> toJson() {
    final map = {
      'menu_id': menuId,
      'addon_name': addonName,
      'price': price,
      'is_required': isRequired,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'Description': description, // Note the capital D to match schema
    };

    // Only include id if it's not null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  FoodAddon copyWith({
    int? id,
    int? menuId,
    String? addonName,
    double? price,
    bool? isRequired,
    int? stockQuantity,
    bool? isAvailable,
    String? description,
  }) {
    return FoodAddon(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      addonName: addonName ?? this.addonName,
      price: price ?? this.price,
      isRequired: isRequired ?? this.isRequired,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      description: description ?? this.description,
    );
  }
}
