class Menu {
  final int id;
  final String foodName;
  final double price;
  final String? photo;
  final String? description;
  final bool isAvailable;
  final int stallId;

  Menu({
    required this.id,
    required this.foodName,
    required this.price,
    this.photo,
    this.description,
    required this.isAvailable,
    required this.stallId,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      foodName: json['food_name'],
      price: (json['price'] as num).toDouble(),
      photo: json['photo'],
      description: json['description'],
      isAvailable: json['is_available'] ?? true,
      stallId: json['stall_id'],
    );
  }
}