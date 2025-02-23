import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/menu_cart_item.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Models/payment_errors.dart' as payment_errors;
import 'package:kantin/Services/Database/restaurant_service.dart';

// class CartItem {
//   final Menu menu;
//   final int quantity;
//   final List<FoodAddon> selectedAddons;
//   final String? note;
//   final double originalPrice;
//   final double discountedPrice;

//   CartItem({
//     required this.menu,
//     required this.quantity,
//     this.selectedAddons = const [],
//     this.note,
//     required this.originalPrice,
//     required this.discountedPrice,
//   });

//   CartItem copyWith({
//     Menu? menu,
//     int? quantity,
//     List<FoodAddon>? selectedAddons,
//     String? note,
//     double? originalPrice,
//     double? discountedPrice,
//   }) {
//     return CartItem(
//       menu: menu ?? this.menu,
//       quantity: quantity ?? this.quantity,
//       selectedAddons: selectedAddons ?? this.selectedAddons,
//       note: note ?? this.note,
//       originalPrice: originalPrice ?? this.originalPrice,
//       discountedPrice: discountedPrice ?? this.discountedPrice,
//     );
//   }

//   double get totalPrice {
//     final itemTotal = discountedPrice * quantity;
//     final addonTotal = selectedAddons.fold(
//       0.0,
//       (sum, addon) => sum + (addon.price * quantity),
//     );
//     return itemTotal + addonTotal;
//   }

//   double get savings {
//     return (originalPrice - discountedPrice) * quantity;
//   }

//   bool get hasDiscount {
//     return discountedPrice < originalPrice;
//   }

//   int get discountPercentage {
//     if (!hasDiscount) return 0;
//     return ((originalPrice - discountedPrice) / originalPrice * 100).round();
//   }

//   double get addonsTotalPrice {
//     return selectedAddons.fold(
//       0.0,
//       (total, addon) => total + (addon.price * quantity),
//     );
//   }
// }

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
    required int quantity,
    List<FoodAddon> addons = const [],
    String? note,
  }) {
    // Debug the incoming menu prices
    print('''
=== Adding Item to Cart ===
Menu: ${menu.foodName}
Original Price: ${menu.price}
Effective Price: ${menu.effectivePrice}
Has Discount: ${menu.hasDiscount}
Discount Percentage: ${menu.discountPercent}
======================
''');

    final cartItem = CartItem(
      menu: menu,
      quantity: quantity,
      selectedAddons: addons,
      note: note,
      originalPrice: menu.price, // Use menu's original price
      discountedPrice: menu.hasDiscount
          ? menu.effectivePrice
          : menu.price, // Use effective price if discounted
    );

    // Debug calculations
    print('''
=== Cart Calculation Debug ===
Item: ${cartItem.menu.foodName}
Original Price: ${cartItem.originalPrice}
Effective Price: ${cartItem.discountedPrice}
Quantity: ${cartItem.quantity}
Savings: ${cartItem.savings}
''');

    // Find existing item
    final existingIndex = _cart.indexWhere((item) =>
        item.menu.id == menu.id &&
        item.note == note &&
        _areAddonsEqual(item.selectedAddons, addons));

    if (existingIndex != -1) {
      _cart[existingIndex] = _cart[existingIndex].copyWith(
        quantity: _cart[existingIndex].quantity + quantity,
      );
    } else {
      _cart.add(cartItem);
    }

    // Print final calculations
    double subtotal = 0.0;
    double totalSavings = 0.0;
    for (var item in _cart) {
      subtotal += item.discountedPrice * item.quantity;
      totalSavings += item.savings;
    }

    print('''
Final Calculations:
Total Items: ${_cart.length}
Subtotal: $subtotal
Total Savings: $totalSavings
Active Discounts: Save Rp ${totalSavings.toStringAsFixed(0)}
=========================
''');

    notifyListeners();
  }

  // Helper method to compare two addon lists
  bool _areAddonsEqual(List<FoodAddon> list1, List<FoodAddon> list2) {
    if (list1.length != list2.length) return false;

    // Sort both lists by addon ID to ensure consistent comparison
    final sortedList1 = List<FoodAddon>.from(list1)
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final sortedList2 = List<FoodAddon>.from(list2)
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

    for (int i = 0; i < sortedList1.length; i++) {
      if (sortedList1[i].id != sortedList2[i].id) return false;
    }

    return true;
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
    final sanitizedAddress = newAddress.trim();
    if (sanitizedAddress.isEmpty) {
      _isValidAddress = false;
      notifyListeners();
      return;
    }

    // Simplified validation - just check minimum length
    if (sanitizedAddress.length < 3) {
      _isValidAddress = false;
      throw payment_errors.PaymentValidationError(
        message:
            'Please provide a valid delivery address (minimum 3 characters)',
      );
    }

    _deliveryAddress = sanitizedAddress;
    _isValidAddress = true;
    notifyListeners();
  }

  bool validateDeliveryAddress() {
    if (_deliveryAddress.trim().isEmpty) {
      throw payment_errors.PaymentValidationError(
        message: 'Delivery address is required',
      );
    }

    if (_deliveryAddress.trim().length < 3) {
      throw payment_errors.PaymentValidationError(
        message:
            'Please provide a valid delivery address (minimum 3 characters)',
      );
    }

    return true;
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
    return _cart.fold(0.0, (sum, item) {
      final itemTotal = item.discountedPrice * item.quantity;
      final addonTotal = item.selectedAddons
          .fold(0.0, (sum, addon) => sum + (addon.price * item.quantity));
      return sum + itemTotal + addonTotal;
    });
  }

  double calculateTotalDiscount() {
    double totalDiscount = 0.0;

    // Debug information
    print('\n=== Calculating Total Discount ===');

    for (var item in cart) {
      final itemDiscount =
          (item.originalPrice - item.discountedPrice) * item.quantity;
      totalDiscount += itemDiscount;

      // Debug output for each item
      print('''
Item: ${item.menu.foodName}
Original Price: ${item.originalPrice}
Discounted Price: ${item.discountedPrice}
Quantity: ${item.quantity}
Item Discount: $itemDiscount
''');
    }

    print('Total Discount: $totalDiscount');
    print('===========================\n');

    return totalDiscount;
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

  // Add this method to help with debugging
  void debugPrintCart() {
    print('\n=== Cart Contents ===');
    for (var item in _cart) {
      print('Item: ${item.menu.foodName}');
      print('Original Price: ${item.originalPrice}');
      print('Discounted Price: ${item.discountedPrice}');
      print('Quantity: ${item.quantity}');
      print('Total: ${item.totalPrice}');
      print('-------------------');
    }
    print('=====================\n');
  }

  bool get hasDiscount {
    return cart.any((item) => item.discountedPrice < item.originalPrice);
  }

  double calculateFinalTotal() {
    final subtotal = calculateSubtotal();
    final discount = calculateTotalDiscount();
    final finalTotal = subtotal - discount;

    // Debug output
    print('''
=== Final Total Calculation ===
Subtotal: $subtotal
Discount: $discount
Final Total: $finalTotal
===========================
''');

    return finalTotal;
  }

  @override
  String toString() {
    return 'Restaurant(items: ${menu.length}, cart: ${cart.length}, total: ${_formatPrice(getTotalPrice())})';
  }
}
