import 'package:kantin/Models/discount.dart';

class MenuDiscount {
  final int id;
  final int menuId;
  final int discountId;
  final bool isActive;
  final Discount? discount;
  final MenuInfo? menu;

  MenuDiscount({
    required this.id,
    required this.menuId,
    required this.discountId,
    required this.isActive,
    this.discount,
    this.menu,
  });

  MenuDiscount copyWith({
    int? id,
    int? menuId,
    int? discountId,
    bool? isActive,
    Discount? discount,
    MenuInfo? menu,
  }) {
    return MenuDiscount(
      id: id ?? this.id,
      menuId: menuId ?? this.menuId,
      discountId: discountId ?? this.discountId,
      isActive: isActive ?? this.isActive,
      discount: discount ?? this.discount,
      menu: menu ?? this.menu,
    );
  }

  factory MenuDiscount.fromJson(Map<String, dynamic> json) {
    return MenuDiscount(
      id: json['id'] as int,
      menuId: json['id_menu'] as int,
      discountId: json['id_discount'] as int,
      isActive: json['is_active'] as bool,
      discount:
          json['discount'] != null ? Discount.fromMap(json['discount']) : null,
      menu: json['menu'] != null ? MenuInfo.fromJson(json['menu']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_menu': menuId,
      'id_discount': discountId,
      'is_active': isActive,
      'discount': discount?.toMap(),
      'menu': menu?.toMap(),
    };
  }
}

class MenuInfo {
  final int id;
  final int stallId;

  MenuInfo({
    required this.id,
    required this.stallId,
  });

  factory MenuInfo.fromJson(Map<String, dynamic> json) {
    return MenuInfo(
      id: json['id'] as int,
      stallId: json['id_stan'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_stan': stallId,
    };
  }
}
