import 'package:kantin/Models/Food.dart';

class CartItem {
  Food food;
  List<foodAddOn> selectedAddOns;
  int quantity;

  CartItem(
      {required this.food, required this.selectedAddOns, this.quantity = 1});
  double get totalprice {
    double addOnsPrice =
        selectedAddOns.fold(0.0, (sum, foodAddOn) => sum + foodAddOn.price);
    return (food.price + addOnsPrice) * quantity;
  }
}
