import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

class CartItem {
  final Menu menu;
  final List<FoodAddon> selectedAddons;
  final String? note;
  final int quantity;

  CartItem({
    required this.menu,
    this.selectedAddons = const [],
    this.note,
    this.quantity = 1,
  });

  double get totalPrice {
    double addonPrice =
        selectedAddons.fold(0, (sum, addon) => sum + (addon.price * quantity));
    return (menu.price * quantity) + addonPrice;
  }
}
