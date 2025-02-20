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
    required this.subtotal,
    this.notes,
    this.status = 'pending',
    this.addons,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final menuPrice =
        json['menu'] != null ? (json['menu']['price'] ?? 0).toDouble() : 0.0;
    final quantity = json['quantity'] ?? 1;

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

    return OrderItem(
      id: json['id'].toString(),
      orderId:
          int.parse((json['transaction_id'] ?? json['orderId']).toString()),
      menuId: json['menu_id'],
      addonId: json['addon_id'],
      userId: json['user_id'],
      stallId: json['stall_id'],
      menu: json['menu'] != null ? Menu.fromJson(json['menu']) : null,
      quantity: quantity,
      unitPrice: menuPrice,
      subtotal: (json['subtotal'] ?? (menuPrice * quantity)).toDouble(),
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      addons: addonDetails,
      createdAt: DateTime.parse(json['created_at']),
    );
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
}
