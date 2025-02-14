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

  Future<void> toggleMenuAvailability(int menuId, bool isAvailable) async {
    try {
      final response = await _client
          .from('menu') // Changed from 'menus' to 'menu'
          .update({'is_available': isAvailable})
          .eq('id', menuId.toString()) // Convert ID to string
          .select()
          .single();

      if (response == null) {
        throw Exception('Menu not found');
      }

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
      
      await _client
          .from('menu')
          .update({'price': newPrice})
          .eq('id', menuId);
    } catch (e) {
      throw 'Failed to update menu price: $e';
    }
  }

  Future<void> duplicateMenu(int menuId) async {
    try {
      // First get the menu to duplicate
      final response = await _client
          .from('menus')
          .select()
          .eq('id', menuId)
          .single();
      
      final originalMenu = Menu.fromJson(response);
      
      // Create new menu with copied data
      final newMenu = originalMenu.copyWith(
        id: null, // Clear ID for new entry
        foodName: '${originalMenu.foodName} (Copy)', // Add (Copy) to name
      );

      // Insert the new menu
      final insertedMenu = await _client
          .from('menus')
          .insert(newMenu.toJson(excludeId: true))
          .select()
          .single();

      // Get original add-ons
      final addons = await getAddonsForMenu(menuId);

      // Duplicate add-ons for new menu
      for (var addon in addons) {
        await createAddon(
          insertedMenu['id'],
          addon.copyWith(id: null), // Clear ID for new entry
        );
      }
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
      // Validate price and quantity
      if (addon.price <= 0) {
        throw Exception('Price must be greater than 0');
      }
      if (addon.stockQuantity != null && addon.stockQuantity! < 0) {
        throw Exception('Stock quantity cannot be negative');
      }

      final response = await _client
          .from('food_addons')
          .insert(addon.toJson())
          .select()
          .single();

      return FoodAddon.fromJson(response);
    } catch (e) {
      if (e.toString().contains('unique_addon_per_menu')) {
        throw Exception('An addon with this name already exists for this menu');
      }
      if (e.toString().contains('check_price_positive')) {
        throw Exception('Price must be greater than 0');
      }
      throw Exception('Failed to create addon: $e');
    }
  }

  /// **🟢 Read: Get all food add-ons for a specific menu**
  Future<List<FoodAddon>> getAddonsForMenu(int menuId) async {
    try {
      final response = await _client
          .from('food_addons')
          .select()
          .eq('menu_id', menuId)
          .order('addon_name');
      
      return (response as List)
          .map((data) => FoodAddon.fromJson(data))
          .toList();
    } catch (e) {
      throw 'Failed to fetch menu add-ons: $e';
    }
  }

  /// **🟡 Update: Update a food add-on**
  Future<void> updateFoodAddon(FoodAddon addon) async {
    try {
      if (addon.id == null) {
        throw Exception('Addon ID is required for update');
      }

      if (addon.price < 0) {
        throw Exception('Price must be greater than or equal to 0');
      }

      await _client
          .from('food_addons')
          .update(addon.toJson())
          .eq('id', addon.id.toString());
    } catch (e) {
      if (e.toString().contains('unique_addon_per_menu')) {
        throw Exception('An addon with this name already exists for this menu');
      }
      print('Error updating addon: $e');
      throw Exception('Failed to update addon: $e');
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
    try {
      if (quantity < 0) {
        throw Exception('Stock quantity cannot be negative');
      }

      await _client
          .from('food_addons')
          .update({'stock_quantity': quantity})
          .eq('id', addonId);
    } catch (e) {
      throw Exception('Failed to update addon stock: $e');
    }
  }

  Future<void> toggleAddonAvailability(int addonId, bool isAvailable) async {
    try {
      await _client
          .from('food_addons')
          .update({'is_available': isAvailable})
          .eq('id', addonId);
    } catch (e) {
      throw Exception('Failed to update addon availability: $e');
    }
  }

  /// **🔴 Delete: Remove a food add-on**
  Future<void> deleteFoodAddon(int id) async {
    try {
      await _client
          .from('food_addons')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Error deleting addon: $e');
      throw Exception('Failed to delete addon: $e');
    }
  }

  Future<void> deleteAddon(int addonId) async {
    try {
      await _client
          .from('menu_addons')
          .delete()
          .eq('id', addonId);
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
}
