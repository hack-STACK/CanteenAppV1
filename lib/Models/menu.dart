class Menu {
  String id; // Firestore document ID
  String name;
  String description;
  double price;
  String imagePath;

  Menu({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
  });

  // Convert a Menu object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imagePath': imagePath,
    };
  }

  // Create a Menu object from a Map object
  factory Menu.fromMap(String id, Map<String, dynamic> map) {
    return Menu(
      id: id,
      name: map['name'],
      description: map['description'],
      price: map['price'],
      imagePath: map['imagePath'],
    );
  }
}