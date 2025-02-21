import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

class CartItem {
  final Menu menu;
  final int quantity;
  final List<FoodAddon> selectedAddons;
  final String? note;
  final double originalPrice;
  final double discountedPrice;

  CartItem({
    required this.menu,
    required this.quantity,
    this.selectedAddons = const [],
    this.note,
    required this.originalPrice,
    required this.discountedPrice,
  });

  double get totalPrice {
    double addonTotal = selectedAddons.fold(
        0, (sum, addon) => sum + (addon.price ?? 0) * quantity);
    return (discountedPrice * quantity) + addonTotal;
  }

  double get savings {
    return (originalPrice - discountedPrice) * quantity;
  }

  bool get hasDiscount {
    return discountedPrice < originalPrice;
  }

  int get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice - discountedPrice) / originalPrice * 100).round();
  }
}
