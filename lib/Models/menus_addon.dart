class FoodAddon {
  final int? id;
  final int menuId;
  final String addonName;
  final double price;
  final bool isRequired;
  final int stockQuantity;
  final bool isAvailable;
  final String? description;
  final String? category; // Add this field

  FoodAddon({
    this.id,
    required this.menuId,
    required this.addonName,
    required this.price,
    this.isRequired = false,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.description,
    this.category = 'Extras', // Default category
  }) {
    if (price <= 0) {
      throw ArgumentError('Price must be greater than 0');
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
      'Description': description,
      'category': category, // Add this field
    };
  }

  factory FoodAddon.fromMap(Map<String, dynamic> map) {
    return FoodAddon(
      id: map['id'] as int?,
      menuId: map['menu_id'] as int,
      addonName: map['addon_name'] as String,
      price: (map['price'] as num).toDouble(),
      isRequired: map['is_required'] as bool? ?? false,
      stockQuantity: map['stock_quantity'] as int? ?? 0,
      isAvailable: map['is_available'] as bool? ?? true,
      description: map['Description'] as String?,
      category: map['category'] as String?, // Add this field
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
      'Description': description,
      'category': category, // Add this field
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
    String? category, // Add this field
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
      category: category ?? this.category, // Add this field
    );
  }
}
