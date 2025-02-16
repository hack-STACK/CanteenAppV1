import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menu_discount.dart';

class DiscountService {
  final SupabaseClient _client;
  static bool debugMode = true;

  DiscountService() : _client = Supabase.instance.client;

  void _logDebug(String message) {
    if (debugMode) {
      print('DiscountService: $message');
    }
  }

  Future<List<Discount>> getDiscounts() async {
    try {
      _logDebug('Fetching discounts...');
      final response = await _client
          .from('discounts')
          .select()
          .order('created_at', ascending: false);

      _logDebug('Received response: $response');

      final List<Discount> discounts = [];
      for (var item in response as List) {
        try {
          discounts.add(Discount.fromMap(item));
        } catch (e) {
          _logDebug('Error parsing discount: $item\nError: $e');
          // Continue with next item instead of failing completely
          continue;
        }
      }

      _logDebug('Successfully parsed ${discounts.length} discounts');
      return discounts;
    } catch (e, stackTrace) {
      _logDebug('Error in getDiscounts: $e\n$stackTrace');
      throw Exception('Failed to fetch discounts: $e');
    }
  }

  Future<Discount> addDiscount(Discount discount) async {
    try {
      _logDebug('Adding discount: ${discount.toMap()}');
      final response = await _client
          .from('discounts')
          .insert(discount.toMap())
          .select()
          .single();

      _logDebug('Received response: $response');

      return Discount.fromMap(response);
    } catch (e, stackTrace) {
      _logDebug('Error in addDiscount: $e\n$stackTrace');
      throw Exception('Failed to add discount: $e');
    }
  }

  Future<void> updateDiscount(Discount discount) async {
    try {
      _logDebug('Updating discount: ${discount.toMap()}');

      // Don't include created_at and updated_at in update
      final map = discount.toMap();

      final response = await _client
          .from('discounts')
          .update(map)
          .eq('id', discount.id)
          .select()
          .single();

      _logDebug('Update response: $response');
    } catch (e, stackTrace) {
      _logDebug('Error updating discount: $e\n$stackTrace');
      throw Exception('Failed to update discount: $e');
    }
  }

  Future<void> toggleDiscountStatus(int discountId, bool newStatus) async {
    try {
      _logDebug('Toggling discount status: $discountId to $newStatus');

      final response = await _client
          .from('discounts')
          .update({'is_active': newStatus})
          .eq('id', discountId)
          .select()
          .single();

      _logDebug('Toggle response: $response');
    } catch (e, stackTrace) {
      _logDebug('Error toggling discount status: $e\n$stackTrace');
      throw Exception('Failed to toggle discount status: $e');
    }
  }

  Future<void> deleteDiscount(int discountId) async {
    try {
      _logDebug('Deleting discount $discountId');
      // This will cascade delete related menu_discounts due to foreign key constraint
      await _client.from('discounts').delete().eq('id', discountId);
      _logDebug('Successfully deleted discount');
    } catch (e, stackTrace) {
      _logDebug('Error in deleteDiscount: $e\n$stackTrace');
      throw Exception('Failed to delete discount: $e');
    }
  }

  Future<void> addMenuDiscount(MenuDiscount menuDiscount) async {
    try {
      _logDebug('Adding menu discount: ${menuDiscount.toMap()}');

      // First, validate the menu and discount exist
      final menuExists = await _client
          .from('menu')
          .select('id')
          .eq('id', menuDiscount.menuId)
          .maybeSingle();

      if (menuExists == null) {
        throw Exception('Menu not found');
      }

      final discountExists = await _client
          .from('discounts')
          .select('id')
          .eq('id', menuDiscount.discountId)
          .maybeSingle();

      if (discountExists == null) {
        throw Exception('Discount not found');
      }

      // Check if this menu-discount combination already exists
      final existing = await _client
          .from('menu_discounts')
          .select()
          .eq('id_menu', menuDiscount.menuId)
          .eq('id_discount', menuDiscount.discountId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('This discount is already applied to this menu item');
      }

      // Insert the menu discount
      final response = await _client
          .from('menu_discounts')
          .insert({
            'id_menu': menuDiscount.menuId,
            'id_discount': menuDiscount.discountId,
          })
          .select()
          .single();

      _logDebug('Successfully added menu discount: $response');
    } catch (e, stackTrace) {
      _logDebug('Error in addMenuDiscount: $e\n$stackTrace');
      if (e.toString().contains('Foreign key violation')) {
        throw Exception('Invalid menu or discount ID');
      }
      if (e.toString().contains('duplicate key')) {
        throw Exception('This discount is already applied to this menu item');
      }
      throw Exception('Failed to apply discount to menu: $e');
    }
  }

  Future<void> deleteMenuDiscount(int menuDiscountId) async {
    try {
      _logDebug('Deleting menu discount $menuDiscountId');
      await _client.from('menu_discounts').delete().eq('id', menuDiscountId);
      _logDebug('Successfully deleted menu discount');
    } catch (e, stackTrace) {
      _logDebug('Error in deleteMenuDiscount: $e\n$stackTrace');
      throw Exception('Failed to delete menu discount: $e');
    }
  }

  Future<List<MenuDiscount>> getMenuDiscounts(int menuId) async {
    try {
      _logDebug('Fetching discounts for menu $menuId');
      final response =
          await _client.from('menu_discounts').select().eq('id_menu', menuId);

      _logDebug('Received response: $response');

      final menuDiscounts =
          (response as List).map((item) => MenuDiscount.fromMap(item)).toList();

      _logDebug('Found ${menuDiscounts.length} discounts for menu $menuId');
      return menuDiscounts;
    } catch (e, stackTrace) {
      _logDebug('Error in getMenuDiscounts: $e\n$stackTrace');
      throw Exception('Failed to fetch menu discounts: $e');
    }
  }
}
