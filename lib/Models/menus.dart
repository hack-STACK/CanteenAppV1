class Menu {
  final int? id;
  final String foodName;
  final double price;
  final String type; // "food" or "drink"
  final String photo;
  final String description;
  final int stallId;

  Menu({
    required this.id,
    required this.foodName,
    required this.price,
    required this.type,
    required this.photo,
    required this.description,
    required this.stallId,
  });

  // Convert from JSON (fetch from Supabase)
  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      foodName: json['food_name'],
      price: json['price'].toDouble(),
      type: json['type'],
      photo: json['photo'],
      description: json['description'],
      stallId: json['stall_id'],
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
    };

    if (!excludeId && id != null) {
      data['id'] = id!; // Include only if updating
    }

    return data;
  }
}
