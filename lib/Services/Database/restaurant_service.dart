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

      // Build the query
      var query = _client.from('menu').select('''
        *,
        menu_discounts(
          id,
          effective_price,
          discount_percentage,
          is_active,
          discounts(
            id,
            discount_name,
            discount_percentage,
            start_date,
            end_date,
            is_active
          )
        )
      ''');

      // Add filters
      if (stallId != null) {
        query = query.eq('stall_id', stallId);
      }

      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      if (type != null) {
        query = query.eq('type', type);
      }

      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      }

      final response = await query;
      print('Menu items found: ${response.length}');

      // Process each menu item
      List<Menu> menus = [];
      for (var item in response) {
        try {
          final menu = Menu.fromMap(item);

          // Check for active discounts
          final menuDiscounts = item['menu_discounts'] as List?;
          if (menuDiscounts != null && menuDiscounts.isNotEmpty) {
            final now = DateTime.now();

            // Find first active discount
            for (var discountData in menuDiscounts) {
              final isActive = discountData['is_active'] == true;
              if (!isActive) continue;

              final discountObj = discountData['discounts'];
              if (discountObj == null) continue;

              final discountIsActive = discountObj['is_active'] == true;
              if (!discountIsActive) continue;

              // Check dates
              final startDate = DateTime.parse(discountObj['start_date']);
              final endDate = DateTime.parse(discountObj['end_date']);

              if (now.isAfter(startDate) && now.isBefore(endDate)) {
                // Calculate discount
                final discountPercentage =
                    (discountObj['discount_percentage'] as num).toDouble();
                final originalPrice = menu.price;
                final discountedPrice =
                    originalPrice * (1 - (discountPercentage / 100));

                // Set discount values on the menu
                menu.setDiscountValues(
                  hasDiscount: true,
                  discountPercentage: discountPercentage,
                  discountedPrice: discountedPrice,
                );

                print(
                    'Applied discount to ${menu.foodName}: $discountPercentage% off');
                print('Original: ${menu.price}, Discounted: $discountedPrice');
                break;
              }
            }
          }

          menus.add(menu);
        } catch (e) {
          print('Error processing menu item: $e');
        }
      }

      return menus;
    } catch (e) {
      print('Error getting menu items: $e');
      throw Exception('Failed to fetch menu items: $e');
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
