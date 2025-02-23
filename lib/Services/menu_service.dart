import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/models/menu_discount.dart';
import 'package:kantin/models/discount.dart';

class MenuService {
  final _supabase = Supabase.instance.client;

  Future<List<MenuDiscount>> getMenuDiscounts(int menuId) async {
    try {
      final response = await _supabase
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

  Future<double> getDiscountedPrice(
    int menuId,
    double originalPrice, {
    int? transactionId,
  }) async {
    final (discountedPrice, _) = await getDiscountedPriceWithTransaction(
      menuId,
      originalPrice,
      transactionId,
    );
    return discountedPrice;
  }

  Future<(double, double?)> getDiscountedPriceWithPercentage(
      int menuId, double originalPrice) async {
    try {
      final response = await _supabase
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
          .lte('discounts.start_date', DateTime.now().toIso8601String())
          .gte('discounts.end_date', DateTime.now().toIso8601String())
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return (originalPrice, null);
      }

      final discount = response['discounts'];
      if (discount == null) {
        return (originalPrice, null);
      }

      final discountPercentage =
          (discount['discount_percentage'] as num).toDouble();
      final discountAmount = originalPrice * (discountPercentage / 100);

      return (originalPrice - discountAmount, discountPercentage);
    } catch (e) {
      print('Error calculating discounted price: $e');
      return (originalPrice, null);
    }
  }

  Future<(double, double?)> getDiscountedPriceWithTransaction(
    int menuId,
    double originalPrice,
    int? transactionId,
  ) async {
    try {
      if (transactionId != null) {
        final transactionDetail = await _supabase
            .from('transaction_details')
            .select(
                'original_price, discounted_price, applied_discount_percentage')
            .eq('transaction_id', transactionId)
            .eq('menu_id', menuId)
            .maybeSingle();

        if (transactionDetail != null) {
          return (
            (transactionDetail['discounted_price'] as num).toDouble(),
            transactionDetail['applied_discount_percentage'] != null
                ? (transactionDetail['applied_discount_percentage'] as num)
                    .toDouble()
                : null
          );
        }
      }

      return await getDiscountedPriceWithPercentage(menuId, originalPrice);
    } catch (e) {
      print('Error calculating discounted price: $e');
      return (originalPrice, null);
    }
  }

  Future<void> lockInDiscount(
    int transactionId,
    int menuId,
    double originalPrice,
    double discountedPrice,
    double discountPercentage,
  ) async {
    try {
      await _supabase
          .from('transaction_details')
          .update({
            'original_price': originalPrice,
            'discounted_price': discountedPrice,
            'applied_discount_percentage': discountPercentage,
          })
          .eq('transaction_id', transactionId)
          .eq('menu_id', menuId);
    } catch (e) {
      print('Error locking in discount: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getLockedInDiscount(
    int transactionId,
    int menuId,
  ) async {
    try {
      final response = await _supabase
          .from('transaction_details')
          .select(
              'original_price, discounted_price, applied_discount_percentage')
          .eq('transaction_id', transactionId)
          .eq('menu_id', menuId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting locked-in discount: $e');
      return null;
    }
  }

  Future<List<Discount>> getActiveMenuDiscounts(int menuId) async {
    try {
      final response = await _supabase.from('menu_discounts').select('''
            *,
            discounts (*)
          ''').eq('id_menu', menuId).eq('is_active', true);

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

  Future<bool> hasActiveDiscount(int menuId) async {
    try {
      final response = await _supabase
          .from('menu_discounts')
          .select('id')
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking active discount: $e');
      return false;
    }
  }

  Future<double> getEffectivePrice(int menuId) async {
    try {
      print('==== Getting effective price ====');
      print('Menu ID: $menuId');

      final response = await _supabase
          .rpc('get_menu_effective_price', params: {'p_menu_id': menuId})
          .select()
          .single();

      print('DB Response: $response');

      final originalPrice = (response['original_price'] as num).toDouble();
      final discountPercentage =
          (response['discount_percentage'] as num).toDouble();
      final discountName = response['discount_name'];

      print('Original Price: $originalPrice');
      print('Discount %: $discountPercentage');
      print('Discount Name: $discountName');

      if (discountPercentage <= 0) {
        print('No discount applied');
        return originalPrice;
      }

      final effectivePrice = originalPrice * (1 - (discountPercentage / 100));
      print('Final Price: $effectivePrice');
      print('========================');

      return effectivePrice;
    } catch (e) {
      print('Error in getEffectivePrice: $e');
      return 0.0;
    }
  }

  Future<double> getDiscountPercentage(int menuId) async {
    try {
      final response = await _supabase
          .from('menu_discounts')
          .select('discount_percentage')
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['discount_percentage'] ?? 0.0;
    } catch (e) {
      print('Error getting discount percentage: $e');
      return 0.0;
    }
  }

  Future<void> updateDiscountStatus(int menuId, bool isActive) async {
    try {
      // First get active discount for this menu
      final discountResponse = await _supabase
          .from('menu_discounts')
          .select('id')
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .maybeSingle();

      if (discountResponse != null) {
        // Update the active status
        await _supabase
            .from('menu_discounts')
            .update({'is_active': isActive}).eq('id', discountResponse['id']);

        print('Updated discount status for menu $menuId to $isActive');
      } else {
        print('No active discount found for menu $menuId');
      }
    } catch (e) {
      print('Error updating discount status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMenuWithDiscounts(int menuId) async {
    try {
      final response = await _supabase.from('menu').select('''
            *,
            menu_discounts!inner (
              effective_price,
              discount_percentage,
              is_active,
              discounts (*)
            )
          ''').eq('id', menuId).eq('menu_discounts.is_active', true).single();

      return response;
    } catch (e) {
      print('Error fetching menu discounts: $e');
      return {};
    }
  }
}
