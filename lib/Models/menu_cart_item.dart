import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

class CartItem {
  final Menu menu;
  int quantity;
  final List<FoodAddon> selectedAddons;
  final String? note;
  final double originalPrice;
  final double discountedPrice;

  CartItem({
    required this.menu,
    this.quantity = 1,
    this.selectedAddons = const [],
    this.note,
    required this.originalPrice,
    required this.discountedPrice,
  });

  CartItem copyWith({
    Menu? menu,
    int? quantity,
    List<FoodAddon>? selectedAddons,
    String? note,
    double? originalPrice,
    double? discountedPrice,
  }) {
    return CartItem(
      menu: menu ?? this.menu,
      quantity: quantity ?? this.quantity,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      note: note ?? this.note,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
    );
  }

  double get totalPrice {
    double basePrice = discountedPrice;
    double addonTotal =
        selectedAddons.fold(0, (sum, addon) => sum + (addon.price * quantity));
    return (basePrice * quantity) + addonTotal;
  }

  double get savings => (originalPrice - discountedPrice) * quantity;

  bool get hasDiscount => discountedPrice < originalPrice;

  int get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice - discountedPrice) / originalPrice * 100).round();
  }
}
