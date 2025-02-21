import 'package:kantin/Services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/models/menu_discount.dart';
import 'package:kantin/models/discount.dart';

class MenuService {
  final supabase = Supabase.instance.client;

  Future<List<MenuDiscount>> getMenuDiscounts(int menuId) async {
    try {
      final response = await supabase
          .from('menu_discounts')
          .select()
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => MenuDiscount.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching menu discounts: $e');
      return [];
    }
  }

  Future<double> getDiscountedPrice(int menuId, double originalPrice) async {
    try {
      final response = await supabase
          .from('menu_discounts')
          .select('''
            id,
            id_menu,
            id_discount,
            is_active,
            discounts!inner (
              id,
              discount_name,
              discount_percentage,
              type,
              is_active,
              start_date,
              end_date
            )
          ''')
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .eq('discounts.is_active', true)
          .limit(1) // Add limit to handle multiple rows
          .maybeSingle(); // Use maybeSingle instead of single to handle no rows

      if (response == null) return originalPrice;

      final discount = response['discounts'];
      if (discount == null) return originalPrice;

      // Check if discount is currently active
      final now = DateTime.now().toUtc();
      final startDate = DateTime.parse(discount['start_date']);
      final endDate = DateTime.parse(discount['end_date']);

      if (!discount['is_active'] ||
          now.isBefore(startDate) ||
          now.isAfter(endDate)) {
        return originalPrice;
      }

      final discountType = discount['type'] as String;

      // Handle integer or double percentage
      final dynamic rawPercentage = discount['discount_percentage'];
      final double percentage = rawPercentage is int
          ? rawPercentage.toDouble()
          : rawPercentage as double;

      if (discountType == 'mainPrice' || discountType == 'both') {
        final discountedPrice = originalPrice * (1 - (percentage / 100));
        return double.parse(
            discountedPrice.toStringAsFixed(2)); // Round to 2 decimal places
      }

      return originalPrice;
    } catch (e, stackTrace) {
      print('Error calculating discounted price: $e');
      if (e is PostgrestException) {
        print('Response data: ${e.message}');
      }
      print('Stack trace: $stackTrace');
      return originalPrice;
    }
  }

  Future<List<Discount>> getActiveMenuDiscounts(int menuId) async {
    try {
      final response = await supabase.from('menu_discounts').select('''
            *,
            discounts (*)
          ''').eq('id_menu', menuId).eq('is_active', true);

      if (response == null) return [];

      final now = DateTime.now().toUtc();

      return (response as List)
          .where((item) => item['discounts'] != null)
          .map((item) =>
              Discount.fromMap(item['discounts'] as Map<String, dynamic>))
          .where((discount) =>
              discount.isActive &&
              now.isAfter(discount.startDate) &&
              now.isBefore(discount.endDate))
          .toList();
    } catch (e) {
      print('Error fetching menu discounts: $e');
      return [];
    }
  }
}
