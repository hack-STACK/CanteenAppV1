import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Services/Database/restaurant_service.dart';

class CartItem {
  final Menu menu;
  final List<FoodAddon> selectedAddons;
  final String? note;
  final int quantity;
  final double originalPrice;
  final double discountedPrice;

  const CartItem({
    required this.menu,
    this.selectedAddons = const [],
    this.note,
    this.quantity = 1,
    required this.originalPrice,
    required this.discountedPrice,
  });

  CartItem copyWith({
    Menu? menu,
    List<FoodAddon>? selectedAddons,
    String? note,
    int? quantity,
    double? originalPrice,
    double? discountedPrice,
  }) {
    return CartItem(
      menu: menu ?? this.menu,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      note: note ?? this.note,
      quantity: quantity ?? this.quantity,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
    );
  }

  double get totalPrice {
    double addonPrice =
        selectedAddons.fold(0, (sum, addon) => sum + (addon.price * quantity));
    return (discountedPrice * quantity) + addonPrice;
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

class Restaurant extends ChangeNotifier {
  final RestaurantService _service = RestaurantService();
  final List<CartItem> _cart = [];
  List<Menu> _menu = []; // Add this
  bool _isLoading = false; // Add this
  String _error = ''; // Add this
  String _deliveryAddress = ''; // Add this
  bool _isValidAddress = true;

  List<CartItem> get cart => _cart;
  List<Menu> get menu => _menu;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get deliveryAddress => _deliveryAddress;
  bool get isValidAddress => _isValidAddress;

  Future<void> loadMenu({
    String? category,
    String? type,
    bool? isAvailable,
    int? stallId,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _menu = await _service.getMenuItems(
        category: category,
        type: type,
        isAvailable: isAvailable,
        stallId: stallId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addToCart(
    Menu menu, {
    int quantity = 1,
    List<FoodAddon> selectedAddons = const [],
    String? note,
    List<FoodAddon> addons = const [],
    double? price,
  }) {
    CartItem newItem = CartItem(
      menu: menu,
      quantity: quantity,
      selectedAddons: selectedAddons,
      note: note,
      originalPrice: menu.price,
      discountedPrice: price ?? menu.price,
    );

    _cart.add(newItem);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    final index = _cart.indexOf(item);
    if (index != -1) {
      if (_cart[index].quantity > 1) {
        _cart[index] =
            _cart[index].copyWith(quantity: _cart[index].quantity - 1);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeLastItem() {
    if (_cart.isNotEmpty) {
      final lastItem = _cart.last;
      if (lastItem.quantity > 1) {
        _cart[_cart.length - 1] =
            lastItem.copyWith(quantity: lastItem.quantity - 1);
      } else {
        _cart.removeLast();
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double getTotalPrice() {
    return _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItemCount {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }

  void updateDeliveryAddress(String newAddress) {
    if (newAddress.trim().isEmpty) {
      _isValidAddress = false;
      notifyListeners();
      return;
    }

    _deliveryAddress = newAddress.trim();
    _isValidAddress = true;
    notifyListeners();
  }

  bool validateOrder() {
    return _isValidAddress && _cart.isNotEmpty;
  }

  String displayReceipt() {
    final receipt = StringBuffer();
    receipt.write("Here's your receipt");
    receipt.writeln();

    String formattedDate =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    receipt.write("Date: $formattedDate");
    receipt.writeln();
    receipt.writeln('--------------------------------');

    for (final CartItem cartItem in _cart) {
      receipt.writeln(
          "${cartItem.quantity} x ${cartItem.menu.foodName} - ${_formatPrice(cartItem.menu.price)}");
      if (cartItem.selectedAddons.isNotEmpty) {
        receipt.write('  Add-ons: ${_formatAddons(cartItem.selectedAddons)}');
      }
      receipt.writeln();
    }

    receipt.writeln('--------------------------------');
    receipt.writeln(
        "Total items: ${_cart.fold(0, (sum, item) => sum + item.quantity)}");
    receipt.write("Total price: ${_formatPrice(getTotalPrice())}");

    return receipt.toString();
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return 'Rp. ${formatter.format(price)}';
  }

  String _formatAddons(List<FoodAddon> addons) {
    return addons
        .map((addon) => '${addon.addonName} (${_formatPrice(addon.price)})')
        .join(', ');
  }

  // Calculate subtotal for all items in cart
  double calculateSubtotal() {
    return cart.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Increase quantity of a cart item
  void increaseQuantity(CartItem item) {
    final index = cart.indexOf(item);
    if (index != -1) {
      cart[index] = cart[index].copyWith(quantity: cart[index].quantity + 1);
      notifyListeners();
    }
  }

  // Decrease quantity of a cart item
  void decreaseQuantity(CartItem item) {
    final index = cart.indexOf(item);
    if (index != -1) {
      if (cart[index].quantity > 1) {
        cart[index] = cart[index].copyWith(quantity: cart[index].quantity - 1);
      } else {
        cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  @override
  String toString() {
    return 'Restaurant(items: ${menu.length}, cart: ${cart.length}, total: ${_formatPrice(getTotalPrice())})';
  }
}
