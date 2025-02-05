// class Menu {
//   final String id;
//   final String name;
//   final String description;
//   final double price;

//   Menu({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.price,
//   });

//   // Factory constructor for creating a Menu from a map
//   factory Menu.fromMap(String id, Map<String, dynamic> map) {
//     return Menu(
//       id: id,
//       name: map['name'] as String,
//       description: map['description'] as String,
//       price: map['price'] as double,
//     );
//   }

//   // Convert a Menu to a map
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'description': description,
//       'price': price,
//     };
//   }
// }
