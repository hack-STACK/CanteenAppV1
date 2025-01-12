import 'package:intl/intl.dart';

class Food {
  final String name;
  final String description;
  final String imagePath;
  final double price;

  final foodCategory category;
  List<foodAddOn> addOns;

  Food({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.price,
    required this.category,
    required this.addOns,
  });
  String formatPrice() {
    final formatter = NumberFormat('#,##0', 'id_ID'); // Indonesian locale
    return 'Rp. ${formatter.format(price)}'; // Format the price
  }
}

enum foodCategory {
  mainCourse, // Makanan Berat
  snacks, // Makanan Ringan
  beverages, // Minuman
  healthy, // Makanan Sehat
  desserts, // Makanan Penutup
}

class foodAddOn {
  String name;
  double price;
  foodAddOn({
    required this.name,
    required this.price,
  });
}
