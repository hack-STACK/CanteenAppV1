import 'package:flutter/foundation.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Models/time_based_discount.dart';

class MenuDetailState extends ChangeNotifier {
  final Menu menu;
  List<FoodAddon> addons;
  List<String> images;
  List<TimeBasedDiscount> discounts;
  bool isEditing;
  bool isLoading;

  MenuDetailState({
    required this.menu,
    this.addons = const [],
    this.images = const [],
    this.discounts = const [],
    this.isEditing = false,
    this.isLoading = false,
  });

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void toggleEditing() {
    isEditing = !isEditing;
    notifyListeners();
  }

  void updateAddons(List<FoodAddon> newAddons) {
    addons = newAddons;
    notifyListeners();
  }

  void updateImages(List<String> newImages) {
    images = newImages;
    notifyListeners();
  }

  void updateDiscounts(List<TimeBasedDiscount> newDiscounts) {
    discounts = newDiscounts;
    notifyListeners();
  }
}
