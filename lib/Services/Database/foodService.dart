import 'package:flutter/foundation.dart';
import 'package:kantin/Models/addon_template.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodService {
  final SupabaseClient _client = Supabase.instance.client;

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
            .update(menu.toJson(excludeId: true))
            .eq('food_name', menu.foodName)
            .select()
            .maybeSingle();

        return Menu.fromJson(response ?? existingMenu);
      } else {
        // Insert new menu
        final response = await _client
            .from('menu')
            .insert(menu.toJson(excludeId: true))
            .select()
            .single();

        return Menu.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to insert/update menu: $e');
    }
  }

  /// **🟢 Read: Get all menu items**
  Future<List<Menu>> getAllMenuItems() async {
    final response = await _client.from('menu').select();
    return response.map<Menu>((json) => Menu.fromJson(json)).toList();
  }

  /// **🟢 Read: Get menu item by ID**
  Future<Menu?> getMenuById(int id) async {
    final response =
        await _client.from('menu').select().eq('id', id).maybeSingle();
    return response != null ? Menu.fromJson(response) : null;
  }

  /// **🟢 Read: Get menu items by stall ID**
  Future<List<Menu>> getMenuByStanId(int stallId) async {
    try {
      print('Fetching menus for stall ID: $stallId');

      final response = await _client
          .from(
              'menu') // Changed from 'menus' to 'menu' to match database table name
          .select()
          .eq('stall_id', stallId)
          .order('id');

      print('Menu Response: $response');

      if (response == null) {
        return [];
      }

      return (response as List).map((menuData) {
        print('Processing menu map: $menuData');
        return Menu.fromMap(menuData);
      }).toList();
    } catch (e) {
      print('Error fetching menus: $e');
      throw 'Failed to load menus: ${e.toString()}';
    }
  }

  /// **🟡 Update: Update a menu item**
  Future<void> updateMenu(Menu menu) async {
    try {
      await _client
          .from('menu')
          .update(menu.toJson(excludeId: true))
          .eq('id', menu.id!)
          .select()
          .maybeSingle(); // Mengembalikan data yang diperbarui
    } catch (e) {
      throw Exception('Failed to update menu: $e');
    }
  }

  Future<void> updateMenuAvailability(int menuId, bool isAvailable) async {
    try {
      await _client
          .from('menu')
          .update({'is_available': isAvailable})
          .match({'id': menuId});
    } catch (e) {
      throw Exception('Failed to update menu availability: $e');
    }
  }

  Future<void> toggleMenuAvailability(int menuId, bool isAvailable) async {
    try {
      await _client
          .from('menu')
          .update({'is_available': isAvailable})
          .eq('id', menuId);
    } catch (e) {
      throw Exception('Failed to toggle menu availability: $e');
    }
  }

  Future<void> updateMenuPrice(int menuId, double newPrice) async {
    try {
      if (newPrice < 0) throw Exception('Price cannot be negative');
      
      await _client
          .from('menu')
          .update({'price': newPrice})
          .eq('id', menuId);
    } catch (e) {
      throw Exception('Failed to update menu price: $e');
    }
  }

  Future<void> duplicateMenu(int menuId) async {
    try {
      // Get original menu
      final originalMenu = await getMenuById(menuId);
      if (originalMenu == null) throw Exception('Menu not found');

      // Create copy with new name
      final copyMenu = originalMenu.copyWith(
        id: null,
        foodName: '${originalMenu.foodName} (Copy)',
      );

      // Insert copy
      final newMenu = await createMenu(copyMenu);

      // Copy addons if any
      final addons = await getAddonsForMenu(menuId);
      for (var addon in addons) {
        await createFoodAddon(addon.copyWith(
          id: null,
          menuId: newMenu.id,
        ));
      }
    } catch (e) {
      throw Exception('Failed to duplicate menu: $e');
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
      // Validate price
      if (addon.price < 0) {
        throw Exception('Price must be greater than or equal to 0');
      }

      final response = await _client
          .from('food_addons')
          .insert(addon.toMap())
          .select()
          .single();

      return FoodAddon.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create addon: $e');
    }
  }

  /// **🟢 Read: Get all food add-ons for a specific menu**
  Future<List<FoodAddon>> getAddonsForMenu(int menuId) async {
    try {
      final response = await _client
          .from('food_addons')
          .select()
          .eq('menu_id', menuId) // Changed from 'id_menu' to 'menu_id'
          .order('id', ascending: true);

      return (response as List).map((data) => FoodAddon.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching addons: $e');
      throw Exception('Failed to fetch addons: $e');
    }
  }

  /// **🟡 Update: Update a food add-on**
  Future<void> updateFoodAddon(FoodAddon addon) async {
    try {
      if (addon.id == null) {
        throw Exception('Addon ID is required for update');
      }

      await _client
          .from('food_addons') // Changed from 'addons' to 'food_addons'
          .update(addon.toMap())
          .eq('id', addon.id!);
    } catch (e) {
      print('Error updating addon: $e');
      throw Exception('Failed to update addon: $e');
    }
  }

  /// **🔴 Delete: Remove a food add-on**
  Future<void> deleteFoodAddon(int id) async {
    try {
      await _client
          .from('food_addons') // Changed from 'addons' to 'food_addons'
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting addon: $e');
      throw Exception('Failed to delete addon: $e');
    }
  }

  // Optimize fetching menu with addons in a single query
  Future<Menu> getMenuWithAddons(int menuId) async {
    try {
      final response = await _client.from('menu').select('''
            *,
            food_addons (
              *
            )
          ''').eq('id', menuId).single();

      final menu = Menu.fromJson(response);
      menu.addons.addAll(
        (response['food_addons'] as List)
            .map((addon) => FoodAddon.fromMap(addon))
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
          .insert(addons.map((addon) => addon.toMap()).toList());
    } catch (e) {
      throw Exception('Failed to create addons: $e');
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
}
