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

  Future<List<Discount>> getDiscountsByStallId(int stallId) async {
    try {
      _logDebug('Fetching discounts for stall $stallId...');
      final response = await _client
          .from('discounts')
          .select()
          .eq('stall_id', stallId)
          .order('created_at', ascending: false);

      _logDebug('Received response: $response');
      final List<Discount> discounts = [];
      for (var item in response as List) {
        try {
          discounts.add(Discount.fromMap(item));
        } catch (e) {
          _logDebug('Error parsing discount: $item\nError: $e');
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

  Future<List<Discount>> getDiscounts() async {
    try {
      _logDebug('Fetching all discounts...');
      final response = await _client
          .from('discounts')
          .select()
          .order('created_at', ascending: false);

      final List<Discount> discounts = [];
      for (var item in response as List) {
        try {
          discounts.add(Discount.fromMap(item));
        } catch (e) {
          _logDebug('Error parsing discount: $item\nError: $e');
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

      return Discount.fromMap(response);
    } catch (e, stackTrace) {
      _logDebug('Error in addDiscount: $e\n$stackTrace');
      throw Exception('Failed to add discount: $e');
    }
  }

  Future<void> updateDiscount(Discount discount) async {
    try {
      _logDebug('Updating discount: ${discount.toMap()}');
      final map = discount.toMap();
      await _client.from('discounts').update(map).eq('id', discount.id);
    } catch (e, stackTrace) {
      _logDebug('Error updating discount: $e\n$stackTrace');
      throw Exception('Failed to update discount: $e');
    }
  }

  Future<void> toggleDiscountStatus(int discountId, bool newStatus) async {
    try {
      _logDebug('Toggling discount status: $discountId to $newStatus');
      await _client
          .from('discounts')
          .update({'is_active': newStatus}).eq('id', discountId);
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
    } catch (e, stackTrace) {
      _logDebug('Error in deleteDiscount: $e\n$stackTrace');
      throw Exception('Failed to delete discount: $e');
    }
  }

  Future<List<MenuDiscount>> getMenuDiscountsByMenuId(int menuId) async {
    try {
      _logDebug('Fetching discounts for menu $menuId');
      final response = await _client.from('menu_discounts').select('''
            *,
            discount:discounts (
              id,
              discount_name,
              discount_percentage,
              start_date,
              end_date,
              is_active,
              type,
              stall_id,
              created_at,
              updated_at
            )
          ''').eq('id_menu', menuId);

      final menuDiscounts = (response as List)
          .map((item) => MenuDiscount.fromJson(item))
          .toList();

      _logDebug('Found ${menuDiscounts.length} discounts for menu $menuId');
      return menuDiscounts;
    } catch (e) {
      _logDebug('Error in getMenuDiscountsByMenuId: $e');
      throw Exception('Failed to fetch menu discounts: $e');
    }
  }

  Future<void> updateMenuDiscount(
      int menuId, int discountId, bool isActive) async {
    try {
      _logDebug(
          'Updating menu discount status: menuId=$menuId, discountId=$discountId, isActive=$isActive');

      final existing = await _client
          .from('menu_discounts')
          .select()
          .eq('id_menu', menuId)
          .eq('id_discount', discountId)
          .maybeSingle();

      if (existing == null && isActive) {
        // Create new relationship if it doesn't exist and we want to activate
        await createMenuDiscount(menuId, discountId, true);
      } else if (existing != null) {
        // Update existing relationship
        await _client
            .from('menu_discounts')
            .update({'is_active': isActive})
            .eq('id_menu', menuId)
            .eq('id_discount', discountId);
      }
    } catch (e) {
      _logDebug('Error updating menu discount: $e');
      throw Exception('Failed to update menu discount: $e');
    }
  }

  Future<void> createMenuDiscount(
      int menuId, int discountId, bool isActive) async {
    try {
      await _client.from('menu_discounts').insert({
        'id_menu': menuId,
        'id_discount': discountId,
        'is_active': isActive,
      });
    } catch (e) {
      _logDebug('Error creating menu discount: $e');
      throw Exception('Failed to create menu discount: $e');
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
      await _client.from('menu_discounts').insert({
        'id_menu': menuDiscount.menuId,
        'id_discount': menuDiscount.discountId,
        'is_active': true,
      });
    } catch (e) {
      _logDebug('Error in addMenuDiscount: $e');
      if (e.toString().contains('Foreign key violation')) {
        throw Exception('Invalid menu or discount ID');
      }
      throw Exception('Failed to apply discount to menu: $e');
    }
  }

  Future<bool> validateDiscountFromMenu(
      int discountId, int menuId, int stallId) async {
    try {
      _logDebug(
          'Starting discount validation: discountId=$discountId, menuId=$menuId, stallId=$stallId');

      // Check if discount exists and get its details
      final discountResponse = await _client
          .from('discounts')
          .select()
          .eq('id', discountId)
          .maybeSingle();

      if (discountResponse == null) {
        _logDebug('Discount not found');
        return false;
      }

      // Check stall ownership
      if (discountResponse['stall_id'] != stallId) {
        _logDebug(
            'Stall ID mismatch: expected=$stallId, actual=${discountResponse['stall_id']}');
        return false;
      }

      // Validate date range
      try {
        final now = DateTime.now();
        final startDate = DateTime.parse(discountResponse['start_date']);
        final endDate = DateTime.parse(discountResponse['end_date']);

        if (now.isBefore(startDate)) {
          _logDebug(
              'Discount not yet active. Starts on: ${startDate.toLocal()}');
          return false;
        }

        if (now.isAfter(endDate)) {
          _logDebug('Discount expired on: ${endDate.toLocal()}');
          return false;
        }
      } catch (e) {
        _logDebug('Error parsing dates: $e');
        return false;
      }

      // Check existing menu discount status
      final menuDiscountResponse = await _client
          .from('menu_discounts')
          .select()
          .eq('id_menu', menuId)
          .eq('id_discount', discountId)
          .maybeSingle();

      // Always allow toggling existing discounts
      if (menuDiscountResponse != null) {
        final isCurrentlyActive = menuDiscountResponse['is_active'] ?? false;
        _logDebug(
            'Existing menu discount found - currently active: $isCurrentlyActive');
        return true; // Allow toggling regardless of current state
      }

      // If no existing menu discount, it can be applied
      _logDebug('No existing menu discount found - can be applied');
      return true;
    } catch (e, stackTrace) {
      _logDebug('Error in validateDiscountFromMenu: $e');
      _logDebug('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Attaches a discount to a menu item
  Future<void> attachMenuDiscount(int menuId, int discountId) async {
    try {
      await _client.from('menu_discounts').insert({
        'id_menu': menuId,
        'id_discount': discountId,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to attach discount: $e');
    }
  }

  /// Detaches a discount from a menu item
  Future<void> detachMenuDiscount(int menuId, int discountId) async {
    try {
      await _client.from('menu_discounts').delete().match({
        'id_menu': menuId,
        'id_discount': discountId,
      });
    } catch (e) {
      throw Exception('Failed to detach discount: $e');
    }
  }

  Future<double> getEffectivePrice(int menuId, double basePrice) async {
    try {
      print('\n=== Calculating Effective Price ===');
      print('Menu ID: $menuId');
      print('Base Price: $basePrice');

      final now = DateTime.now().toIso8601String();

      // Get active discount for the menu
      final response = await _client
          .from('menu_discounts')
          .select('''
            *,
            discount:discounts (
              discount_percentage,
              is_active,
              start_date,
              end_date
            )
          ''')
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .eq('discount.is_active', true)
          .lte('discount.start_date', now)
          .gte('discount.end_date', now)
          .maybeSingle();

      if (response == null) {
        print('No active discount found');
        return basePrice;
      }

      print('Found discount: $response');

      // First try to use effective_price if available
      if (response['effective_price'] != null) {
        final effectivePrice = (response['effective_price'] as num).toDouble();
        print('Using pre-calculated effective price: $effectivePrice');
        return effectivePrice;
      }

      // Then try discount_percentage from menu_discounts
      if (response['discount_percentage'] != null) {
        final percentage = (response['discount_percentage'] as num).toDouble();
        final discountedPrice = basePrice * (1 - (percentage / 100));
        print('Calculated from menu_discounts percentage: $discountedPrice');
        return discountedPrice;
      }

      // Finally try discount_percentage from discounts table
      if (response['discount']?['discount_percentage'] != null) {
        final percentage =
            (response['discount']['discount_percentage'] as num).toDouble();
        final discountedPrice = basePrice * (1 - (percentage / 100));
        print('Calculated from discounts percentage: $discountedPrice');
        return discountedPrice;
      }

      print('No valid discount percentage found, using base price');
      return basePrice;
    } catch (e) {
      print('Error calculating effective price: $e');
      return basePrice; // Return original price on error
    }
  }

  Future<double?> getDiscountPercentage(int menuId) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('menu_discounts')
          .select('''
            discount_percentage,
            discount:discounts (
              discount_percentage
            )
          ''')
          .eq('id_menu', menuId)
          .eq('is_active', true)
          .eq('discount.is_active', true)
          .lte('discount.start_date', now)
          .gte('discount.end_date', now)
          .maybeSingle();

      if (response == null) return null;

      // Try menu_discounts percentage first
      if (response['discount_percentage'] != null) {
        return (response['discount_percentage'] as num).toDouble();
      }

      // Then try discounts table percentage
      if (response['discount']?['discount_percentage'] != null) {
        return (response['discount']['discount_percentage'] as num).toDouble();
      }

      return null;
    } catch (e) {
      print('Error getting discount percentage: $e');
      return null;
    }
  }
}
