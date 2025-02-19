import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/menus.dart';

class RestaurantService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Menu>> getMenuItems({
    String? category,
    String? type,
    bool? isAvailable,
    int? stallId,
  }) async {
    try {
      var query = _client.from('menu').select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (type != null) {
        query = query.eq('type', type);
      }
      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      }
      if (stallId != null) {
        query = query.eq('stall_id', stallId);
      }

      final response = await query.order('food_name');
      return (response as List).map((item) => Menu.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to load menu items: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _client
          .from('menu')
          .select('category')
          .not('category', 'is', null);
      return (response as List).map((item) => item['category'] as String).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<Menu> getMenuItem(int id) async {
    try {
      final response = await _client
          .from('menu')
          .select()
          .eq('id', id)
          .single();
      return Menu.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load menu item: $e');
    }
  }
}