import 'package:supabase_flutter/supabase_flutter.dart';

class PricingService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getMenuPricing(int menuId) async {
    final response = await _supabase
        .from('menu')
        .select('price, discounts!menu_id(*)')
        .eq('id', menuId)
        .single();

    final basePrice = (response['price'] as num).toDouble();
    final discounts = response['discounts'] as List<dynamic>? ?? [];

    // Calculate active discount if any
    double discountedPrice = basePrice;
    if (discounts.isNotEmpty) {
      final activeDiscount = discounts.firstWhere(
        (d) => d['is_active'] == true,
        orElse: () => null,
      );
      if (activeDiscount != null) {
        final discountAmount = (activeDiscount['amount'] as num).toDouble();
        discountedPrice = basePrice - (basePrice * discountAmount);
      }
    }

    return {
      'basePrice': basePrice,
      'discountedPrice': discountedPrice,
      'hasDiscount': discountedPrice < basePrice,
    };
  }

  Future<List<Map<String, dynamic>>> getMenuAddons(int menuId) async {
    return await _supabase
        .from('food_addons')
        .select()
        .eq('menu_id', menuId)
        .order('name');
  }
}
