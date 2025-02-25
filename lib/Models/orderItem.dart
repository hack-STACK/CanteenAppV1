import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

class OrderItem {
  final String id;
  final int orderId; // Change to int since it comes from transaction_id
  final int? menuId;
  final int? addonId;
  final String? userId;
  final int? stallId;
  final Menu? menu;
  final int quantity;
  final double unitPrice; // Add this
  final double originalUnitPrice;  // Added field to store original price
  final double discountPercentage; // Added field for discount percentage
  final double subtotal;
  final String? notes;
  final String status;
  final List<OrderAddonDetail>? addons;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    this.menuId,
    this.addonId,
    this.userId,
    this.stallId,
    this.menu,
    required this.quantity,
    required this.unitPrice, // Add this
    this.originalUnitPrice = 0.0,  // Default to 0.0
    this.discountPercentage = 0.0, // Default to 0.0
    required this.subtotal,
    this.notes,
    this.status = 'pending',
    this.addons,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Menu? menuItem;
    if (json['menu'] != null) {
      menuItem = Menu.fromJson(json['menu']);
      print('DEBUG OrderItem Menu Info:');
      print('Menu Item: ${menuItem.foodName}');
      print('Base Price: ${menuItem.price}');
      print('Original Price: ${menuItem.originalPrice}');
      print('Discounted Price: ${menuItem.discountedPrice}');
      print('Has Discount: ${menuItem.hasDiscount}');
    }

    final quantity = json['quantity'] ?? 1;
    double originalPrice = 0.0;
    double discountedPrice = 0.0;
    double discountPercentage = 0.0;
    
    // Handle different price scenarios
    if (json['original_price'] != null) {
      originalPrice = (json['original_price'] as num).toDouble();
    } else if (menuItem?.originalPrice != null) {
      originalPrice = menuItem!.originalPrice!;
    } else if (menuItem?.price != null) {
      originalPrice = menuItem!.price;
    }
    
    if (json['discounted_price'] != null) {
      discountedPrice = (json['discounted_price'] as num).toDouble();
    } else if (menuItem?.discountedPrice != null) {
      discountedPrice = menuItem!.discountedPrice!;
    } else if (json['unit_price'] != null) {
      discountedPrice = (json['unit_price'] as num).toDouble();
    } else if (menuItem?.price != null) {
      discountedPrice = menuItem!.price;
    }
    
    if (json['applied_discount_percentage'] != null) {
      discountPercentage = (json['applied_discount_percentage'] as num).toDouble();
    } else if (menuItem?.discountPercent != null) {
      discountPercentage = menuItem!.discountPercent;
    } else if (originalPrice > 0 && discountedPrice > 0 && originalPrice > discountedPrice) {
      discountPercentage = ((originalPrice - discountedPrice) / originalPrice) * 100;
    }
    
    // If we couldn't determine the original price, use the discounted price
    if (originalPrice <= 0) {
      originalPrice = discountedPrice;
    }

    // Calculate subtotal using discounted price
    final subtotal =
        (json['subtotal'] as num?)?.toDouble() ?? (discountedPrice * quantity);

    print('Calculated Subtotal: $subtotal');

    List<OrderAddonDetail> addonDetails = [];

    if (json['addon'] != null) {
      final addon = json['addon'];
      final addonId = (addon['id'] as num).toInt();
      addonDetails.add(OrderAddonDetail(
        id: addonId.toString(),
        addonId: addonId,
        addonName: addon['addon_name'] as String? ?? 'Unknown Addon',
        price: (addon['price'] as num?)?.toDouble() ?? 0.0,
        quantity: quantity,
        unitPrice: (addon['price'] as num?)?.toDouble() ?? 0.0,
        subtotal: ((addon['price'] as num?)?.toDouble() ?? 0.0) * quantity,
      ));
    }
    
    // Process addon data from transaction_details
    if (json['addon_name'] != null && json['addon_price'] != null) {
      addonDetails.add(OrderAddonDetail(
        id: json['id'].toString(),
        addonId: 0, // Default value since we don't have the actual addon_id
        addonName: json['addon_name'].toString(),
        price: (json['addon_price'] as num).toDouble(),
        quantity: json['addon_quantity'] ?? 1,
        unitPrice: (json['addon_price'] as num).toDouble(),
        subtotal: (json['addon_subtotal'] as num?)?.toDouble() ?? 
                 ((json['addon_price'] as num).toDouble() * (json['addon_quantity'] ?? 1)),
      ));
    }

    return OrderItem(
      id: json['id'].toString(),
      orderId:
          int.parse((json['transaction_id'] ?? json['orderId']).toString()),
      menuId: json['menu_id'],
      addonId: json['addon_id'],
      userId: json['user_id'],
      stallId: json['stall_id'],
      menu: menuItem,
      quantity: quantity,
      unitPrice: discountedPrice,
      originalUnitPrice: originalPrice,
      discountPercentage: discountPercentage,
      subtotal: subtotal,
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      addons: addonDetails.isNotEmpty ? addonDetails : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  // Update calculation methods
  bool get hasDiscount => originalUnitPrice > unitPrice;

  double get originalSubtotal => originalUnitPrice * quantity;

  double get savings => hasDiscount ? originalSubtotal - subtotal : 0;

  double get totalWithAddons {
    double baseTotal = subtotal;
    if (addons != null) {
      baseTotal += addons!.fold(0.0, (sum, addon) => sum + (addon.subtotal));
    }
    return baseTotal;
  }
}

class OrderAddonDetail {
  final String id;
  final int addonId;
  final FoodAddon? addon; // Add this field
  final String addonName;
  final double price;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderAddonDetail({
    required this.id,
    required this.addonId,
    this.addon,
    required this.addonName,
    required this.price,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderAddonDetail.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] ?? 0).toDouble();
    final quantity = json['quantity'] ?? 1;

    return OrderAddonDetail(
      id: json['id'].toString(),
      addonId: json['addon_id'] ?? 0,
      addon: json['addon'] != null ? FoodAddon.fromJson(json['addon']) : null,
      addonName: json['addon_name'] ?? json['name'] ?? 'Unknown Addon',
      price: price,
      quantity: quantity,
      unitPrice: price,
      subtotal: price * quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'addon_id': addonId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'addon': addon?.toJson(),
    };
  }
}
