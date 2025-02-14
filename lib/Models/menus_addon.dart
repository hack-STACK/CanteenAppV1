class FoodAddon {
  final int? id;
  final int menuId;
  final String addonName;
  final double price;
  final bool isRequired;
  final String? description;
  final int? stockQuantity;
  final bool isAvailable;

  FoodAddon({
    this.id,
    required this.menuId,
    required this.addonName,
    required this.price,
    this.isRequired = false, // Default to false as per DB schema
    this.description,
    this.stockQuantity = 0,
    this.isAvailable = true,
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
    if (stockQuantity != null && stockQuantity! < 0) {
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
      'description': description,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
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
      stockQuantity: map['stock_quantity'] as int?,
      isAvailable: map['is_available'] as bool? ?? true,
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
    };

    // Only include id if it's not null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  FoodAddon copyWith({
    int? id,
    String? addonName,
    double? price,
    String? description,
    int? menuId,
    bool? isRequired,
    int? stockQuantity,
    bool? isAvailable,
  }) {
    return FoodAddon(
      id: id ?? this.id,
      addonName: addonName ?? this.addonName,
      price: price ?? this.price,
      description: description ?? this.description,
      menuId: menuId ?? this.menuId,
      isRequired: isRequired ?? this.isRequired,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
