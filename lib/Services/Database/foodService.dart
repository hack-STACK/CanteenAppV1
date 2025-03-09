import 'package:kantin/Models/addon_template.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/utils/network_utils.dart';
import 'package:kantin/retry_helper.dart';

class FoodService {
  final SupabaseClient _client = Supabase.instance.client;
  final _supabase = Supabase.instance.client;

  /// **🔵 Create: Insert or update a menu item**
  Future<Menu> createMenu(Menu menu) async {
    try {
      final existingMenu = await _client
          .from('menu')
          .select()
          .eq('food_name', menu.foodName)
          .maybeSingle();

      if (existingMenu != null) {
        // Update existing menu
        final response = await _client
            .from('menu')
            .update(menu.toMap()) // Change toJson to toMap
            .eq('food_name', menu.foodName)
            .select()
            .maybeSingle();

        return Menu.fromMap(
            response ?? existingMenu); // Change fromJson to fromMap
      } else {
        // Insert new menu - exclude ID to let database generate it
        final menuData = menu.toMap()..remove('id');

        final response =
            await _client.from('menu').insert(menuData).select().single();

        return Menu.fromMap(response); // Change fromJson to fromMap
      }
    } catch (e) {
      throw Exception('Failed to insert/update menu: $e');
    }
  }

  /// **🟢 Read: Get all menu items**
  Future<List<Menu>> getAllMenuItems() async {
    final response = await _client.from('menu').select();
    return response
        .map<Menu>((json) => Menu.fromMap(json))
        .toList(); // Change fromJson to fromMap
  }

  /// **🟢 Read: Get menu item by ID**
  Future<Menu?> getMenuById(int id) async {
    try {
      final response = await _client.from('menu').select('''
        *,
        menu_discounts!inner (
          discount_percentage,
          is_active,
          discounts (
            id,
            discount_name,
            start_date,
            end_date
          )
        )
      ''').eq('id', id).single();

      print('DEBUG Raw Menu Response:');
      print(response);

      return Menu.fromJson(response);
    } catch (e) {
      print('Error getting menu by ID: $e');
      rethrow;
    }
  }

  /// **🟢 Read: Get menu items by stall ID**
  Future<List<Menu>> getMenuByStanId(int stanId) async {
    try {
      final response = await _client
          .from('menu')
          .select('''
          *,
          menu_discounts!left (
            id,
            is_active,
            discounts!left (
              id,
              discount_name,
              discount_percentage,
              start_date,
              end_date,
              is_active
            )
          )
        ''')
          .eq('stall_id', stanId)
          .eq('menu_discounts.discounts.is_active', true)
          .gte('menu_discounts.discounts.end_date',
              DateTime.now().toIso8601String());

      print('DEBUG Raw Response:');
      print(response);

      return (response as List).map((map) {
        // Add discount info to menu
        if (map['menu_discounts'] != null &&
            (map['menu_discounts'] as List).isNotEmpty) {
          var discount = map['menu_discounts'][0]['discounts'];
          if (discount != null) {
            map['original_price'] = map['price'];
            map['discounted_price'] =
                map['price'] * (1 - (discount['discount_percentage'] / 100));
          }
        }
        return Menu.fromJson(map);
      }).toList();
    } catch (e, stackTrace) {
      print('Error fetching menus: $e\n$stackTrace');
      throw Exception('Failed to load menus: $e');
    }
  }

  /// Get menu items by stall ID and type
  Future<List<Menu>> getMenuByStanIdAndType(int stanId, String type) async {
    try {
      final response = await _client
          .from('menu')
          .select()
          .eq('stall_id', stanId)
          .eq('type', type)
          .order('food_name');

      return (response as List).map((map) => Menu.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load $type items: $e');
    }
  }

  /// Get categorized menus for a stall
  Future<Map<String, List<Menu>>> getCategorizedMenus(int stanId) async {
    try {
      final allMenus = await getMenuByStanId(stanId);

      return {
        'food': allMenus.where((menu) => menu.type == 'food').toList(),
        'drink': allMenus.where((menu) => menu.type == 'drink').toList(),
      };
    } catch (e) {
      throw Exception('Failed to load categorized menus: $e');
    }
  }

  /// **🟡 Update: Update a menu item**
  Future<void> updateMenu(Menu menu) async {
    try {
      await _client
          .from('menu')
          .update(menu.toJson(excludeId: true))
          .eq('id', menu.id)
          .select()
          .maybeSingle(); // Mengembalikan data yang diperbarui
    } catch (e) {
      throw Exception('Failed to update menu: $e');
    }
  }

  /// Update a menu item using a map of properties
  Future<void> updateMenuWithMap(Map<String, dynamic> menuData) async {
    try {
      if (!menuData.containsKey('id')) {
        throw Exception('Menu ID is required for update');
      }

      final menuId = menuData['id'];

      // Create a clean copy of the data for the update
      final updateData = Map<String, dynamic>.from(menuData);

      // Remove any fields that don't exist in the database
      updateData
          .removeWhere((key, value) => ['id', 'is_popular'].contains(key));

      print('Updating menu with data: $updateData');

      await _client.from('menu').update(updateData).eq('id', menuId);
    } catch (e) {
      print('Error updating menu with map: $e');
      throw Exception('Failed to update menu: $e');
    }
  }

  Future<void> toggleMenuAvailability(int menuId, bool isAvailable) async {
    try {
      final response = await _client
          .from('menu') // Changed from 'menus' to 'menu'
          .update({'is_available': isAvailable})
          .eq('id', menuId.toString()) // Convert ID to string
          .select()
          .single();
    } catch (e) {
      print('Error toggling menu availability: $e');
      if (e.toString().contains('not found')) {
        throw 'Menu not found';
      }
      throw 'Failed to update menu availability. Please try again.';
    }
  }

  Future<void> updateMenuPrice(int menuId, double newPrice) async {
    try {
      if (newPrice < 0) throw Exception('Price cannot be negative');

      await _client.from('menu').update({'price': newPrice}).eq('id', menuId);
    } catch (e) {
      throw 'Failed to update menu price: $e';
    }
  }

  Future<void> duplicateMenu(int menuId) async {
    try {
      // First get the menu to duplicate
      final response =
          await _client.from('menu').select().eq('id', menuId).single();
      final originalMenu = Menu.fromJson(response);

      // Create new menu with copied data
      final newMenu = originalMenu.copyWith(
        id: null,
        foodName: '${originalMenu.foodName} (Copy)',
        isAvailable: true, // Ensure the new menu is available
      );

      // Insert the new menu
      final insertedMenu = await _client
          .from('menu')
          .insert(newMenu.toJson(excludeId: true))
          .select()
          .single();

      // Get original add-ons
      final addons = await getAddonsForMenu(menuId);

      // Duplicate add-ons for new menu in parallel
      final addonFutures = addons.map((addon) {
        final newAddon = addon.copyWith(
          id: null,
          menuId: insertedMenu['id'],
        );
        return createFoodAddon(newAddon);
      });

      await Future.wait(addonFutures);
    } catch (e) {
      throw 'Failed to duplicate menu: $e';
    }
  }

  /// **🔴 Delete: Remove a menu item**
  Future<void> deleteMenu(int id) async {
    try {
      await _client.from('menu').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete menu: $e');
    }
  }

  /// **🔵 Create: Insert a new food add-on**
  Future<FoodAddon> createFoodAddon(FoodAddon addon) async {
    try {
      final response = await _client
          .from('food_addons')
          .insert({
            'menu_id': addon.menuId,
            'addon_name': addon.addonName,
            'price': addon.price,
            'is_required': addon.isRequired,
            'Description': addon.description, // Fixed: Changed to "Description"
          })
          .select()
          .single();

      return FoodAddon.fromMap(response);
    } catch (e) {
      print('Error creating addon: $e');
      throw Exception('Failed to create addon: $e');
    }
  }

  /// **🟢 Read: Get all food add-ons for a specific menu**
  Future<List<FoodAddon>> getAddonsForMenu(int menuId) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection');
    }

    try {
      final response = await retry(() async {
        final result = await _supabase
            .from('food_addons')
            .select()
            .eq('menu_id', menuId)
            .order('addon_name');

        return (result as List).map((data) => FoodAddon.fromMap(data)).toList();
      });

      return response;
    } catch (e) {
      throw Exception('Failed to load add-ons: $e');
    }
  }

  /// **🟡 Update: Update a food add-on**
  Future<FoodAddon> updateFoodAddon(FoodAddon addon) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection');
    }

    try {
      final response = await retry(() async {
        final data = {
          'addon_name': addon.addonName,
          'price': addon.price,
          'is_required': addon.isRequired,
          'Description': addon.description, // Fixed: Changed to "Description"
          // Don't update menu_id as it's part of a unique constraint
        };

        final result = await _supabase
            .from('food_addons')
            .update(data)
            .eq('id', addon.id!)
            .select()
            .single();

        return FoodAddon.fromMap(result);
      });

      return response;
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '23505') {
          throw Exception(
              'An add-on with this name already exists for this menu');
        }
        if (e.code == '23514') {
          throw Exception('Price must be greater than 0');
        }
      }
      throw Exception('Failed to update add-on: $e');
    }
  }

  Future<void> updateAddon(FoodAddon addon) async {
    try {
      await _client
          .from('menu_addons')
          .update(addon.toJson())
          .eq('id', addon.id!);
    } catch (e) {
      throw 'Failed to update add-on: $e';
    }
  }

  Future<void> updateAddonStock(int addonId, int quantity) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection');
    }

    try {
      await retry(() async {
        await _supabase
            .from('food_addons')
            .update({'stock_quantity': quantity}).eq('id', addonId);
      });
    } catch (e) {
      throw Exception('Failed to update add-on stock: $e');
    }
  }

  Future<void> toggleAddonAvailability(int addonId, bool isAvailable) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection');
    }

    try {
      await retry(() async {
        await _supabase
            .from('food_addons')
            .update({'is_available': isAvailable}).eq('id', addonId);
      });
    } catch (e) {
      throw Exception('Failed to update add-on availability: $e');
    }
  }

  /// **🔴 Delete: Remove a food add-on**
  Future<void> deleteFoodAddon(int id) async {
    if (!await hasInternetConnection()) {
      throw Exception('No internet connection');
    }

    try {
      await retry(() async {
        await _supabase.from('food_addons').delete().eq('id', id);
      });
    } catch (e) {
      throw Exception('Failed to delete add-on: $e');
    }
  }

  Future<void> deleteAddon(int addonId) async {
    try {
      await _client.from('menu_addons').delete().eq('id', addonId);
    } catch (e) {
      throw 'Failed to delete add-on: $e';
    }
  }

  // Optimize fetching menu with addons in a single query
  Future<Menu> getMenuWithAddons(int menuId) async {
    try {
      final response = await _client.from('menu').select('''
            *,
            food_addons (
              id,
              menu_id,
              addon_name,
              price,
              is_required,
              stock_quantity,
              is_available
            )
          ''').eq('id', menuId).single();

      final menu = Menu.fromJson(response);
      menu.addons.addAll(
        (response['food_addons'] as List)
            .map((addon) => FoodAddon.fromJson(addon))
            .toList(),
      );
      return menu;
    } catch (e) {
      throw Exception('Failed to fetch menu with addons: $e');
    }
  }

  // Batch create addons for better performance
  Future<void> createFoodAddons(List<FoodAddon> addons) async {
    try {
      if (addons.isEmpty) return;

      await _client
          .from('food_addons')
          .insert(addons.map((addon) => addon.toJson()).toList());
    } catch (e) {
      if (e.toString().contains('unique_addon_per_menu')) {
        throw Exception('Some addons already exist for their respective menus');
      }
      throw Exception('Failed to create addons: $e');
    }
  }

  Future<FoodAddon> createAddon(int menuId, FoodAddon addon) async {
    try {
      final response = await _client
          .from('menu_addons')
          .insert(addon.toJson()..addAll({'menu_id': menuId}))
          .select()
          .single();

      return FoodAddon.fromJson(response);
    } catch (e) {
      throw 'Failed to create add-on: $e';
    }
  }

  /// Get all available add-on templates
  Future<List<AddonTemplate>> getAddonTemplates() async {
    try {
      final response = await _client
          .from('addon_templates')
          .select()
          .order('use_count', ascending: false);

      return (response as List)
          .map((data) => AddonTemplate.fromMap(data))
          .toList();
    } catch (e) {
      print('Error fetching addon templates: $e');
      throw Exception('Failed to fetch addon templates: $e');
    }
  }

  Future<void> updateMenuWithAddons(Menu menu, List<FoodAddon> addons) async {
    try {
      // Start a transaction
      await _client.rpc('begin_transaction');

      // First update the menu
      await updateMenu(menu);

      // Delete existing addons for this menu
      await _client.from('food_addons').delete().eq('menu_id', menu.id);

      // Insert new addons
      if (addons.isNotEmpty) {
        final addonsData = addons
            .map((addon) => {
                  'menu_id': menu.id,
                  'addon_name': addon.addonName,
                  'price': addon.price,
                  'is_required': addon.isRequired,
                  'Description': addon.description,
                })
            .toList();

        await _client.from('food_addons').insert(addonsData);
      }

      // Commit transaction
      await _client.rpc('commit_transaction');
    } catch (e) {
      // Rollback on error
      await _client.rpc('rollback_transaction');
      print('Error updating menu with addons: $e');
      throw Exception('Failed to update menu with addons: $e');
    }
  }
}
