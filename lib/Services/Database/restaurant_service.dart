import 'package:kantin/Services/Database/discountService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/menus.dart';

class RestaurantService {
  final SupabaseClient _client = Supabase.instance.client;
  final DiscountService _discountService = DiscountService(); // Add this line

  Future<List<Menu>> getMenuItems({
    String? category,
    String? type,
    bool? isAvailable,
    int? stallId,
  }) async {
    try {
      print('\n=== Getting Menu Items ===');

      // Simple query to get all menus
      var query = _client.from('menu').select('*');

      if (stallId != null) {
        query = query.eq('stall_id', stallId);
      }

      final response = await query;
      print('Raw DB Response: $response');

      // Process each menu item with its discount
      return Future.wait((response as List).map((item) async {
        final basePrice = (item['price'] as num).toDouble();
        final menuId = item['id'] as int;

        // Get discount information
        final effectivePrice =
            await _discountService.getEffectivePrice(menuId, basePrice);
        final discountPercentage =
            await _discountService.getDiscountPercentage(menuId);

        print('Menu: ${item['food_name']}');
        print('Base Price: $basePrice');
        print('Effective Price: $effectivePrice');
        print('Discount Percentage: $discountPercentage');

        return Menu.fromMap({
          ...item,
          'original_price': basePrice,
          'discounted_price':
              effectivePrice != basePrice ? effectivePrice : null,
        });
      }));
    } catch (e, stack) {
      print('Error in getMenuItems: $e\n$stack');
      throw Exception('Failed to load menu items: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _client
          .from('menu')
          .select('category')
          .not('category', 'is', null);
      return (response as List)
          .map((item) => item['category'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<Menu> getMenuItem(int id) async {
    try {
      final response =
          await _client.from('menu').select().eq('id', id).single();
      return Menu.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load menu item: $e');
    }
  }
}
