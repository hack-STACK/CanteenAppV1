class Menu {
  final int id;
  final String foodName;
  final double originalPrice;
  final double price;
  final String? photo;
  final String? description;
  final bool isAvailable;
  final int stallId;

  Menu({
    required this.id,
    required this.foodName,
    required this.originalPrice,
    required this.price,
    this.photo,
    this.description,
    required this.isAvailable,
    required this.stallId,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final originalPrice = (json['price'] as num).toDouble();
    final discountPercentage = (json['discount'] as num?)?.toDouble() ?? 0.0;
    final price = discountPercentage > 0
        ? originalPrice - (originalPrice * discountPercentage / 100)
        : originalPrice;

    return Menu(
      id: json['id'],
      foodName: json['food_name'],
      originalPrice: originalPrice,
      price: price,
      photo: json['photo'],
      description: json['description'],
      isAvailable: json['is_available'] ?? true,
      stallId: json['stall_id'],
    );
  }
}
