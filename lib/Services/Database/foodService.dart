import 'package:flutter/foundation.dart';
import 'package:kantin/Models/Food.dart';
import 'package:kantin/Models/addon_template.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// **🔵 Create: Insert or update a menu item**
  Future<Menu> createMenu(Menu menu) async {
    try {
      final existingMenu = await _supabase
          .from('menu')
          .select()
          .eq('food_name', menu.foodName)
          .maybeSingle();

      if (existingMenu != null) {
        // Update existing menu
        final response = await _supabase
            .from('menu')
            .update(menu.toJson(excludeId: true))
            .eq('food_name', menu.foodName)
            .select()
            .maybeSingle();

        return Menu.fromJson(response ?? existingMenu);
      } else {
        // Insert new menu
        final response = await _supabase
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
    final response = await _supabase.from('menu').select();
    return response.map<Menu>((json) => Menu.fromJson(json)).toList();
  }

  /// **🟢 Read: Get menu item by ID**
  Future<Menu?> getMenuById(int id) async {
    final response =
        await _supabase.from('menu').select().eq('id', id).maybeSingle();
    return response != null ? Menu.fromJson(response) : null;
  }

  /// **🟢 Read: Get menu items by stall ID**
  Future<List<Menu>> getMenuByStanId(int? stanId) async {
    if (stanId == null) return [];

    try {
      final response = await _supabase
          .from('menu')
          .select()
          .eq('stall_id', stanId); // Changed from 'stan_id' to 'stall_id'

      return (response as List<dynamic>)
          .map((menu) => Menu.fromJson(menu))
          .toList();
    } catch (e) {
      debugPrint('Error fetching menus for stan $stanId: $e');
      return [];
    }
  }

  /// **🟡 Update: Update a menu item**
  Future<void> updateMenu(Menu menu) async {
    try {
      await _supabase
          .from('menu')
          .update(menu.toJson(excludeId: true))
          .eq('id', menu.id!)
          .select()
          .maybeSingle(); // Mengembalikan data yang diperbarui
    } catch (e) {
      throw Exception('Failed to update menu: $e');
    }
  }

  /// **🔴 Delete: Remove a menu item**
  Future<void> deleteMenu(int id) async {
    try {
      await _supabase.from('menu').delete().eq('id', id);
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

      final response = await _supabase
          .from('food_addons')
          .insert(addon.toMap())
          .select()
          .single();

      return FoodAddon.fromMap(response);
    } catch (e) {
      if (e.toString().contains('unique_addon_per_menu')) {
        throw Exception(
            'An add-on with this name already exists for this menu');
      }
      print('Error creating addon: $e');
      throw Exception('Failed to create addon: $e');
    }
  }

  /// **🟢 Read: Get all food add-ons for a specific menu**
  Future<List<FoodAddon>> getAddonsForMenu(int menuId) async {
    try {
      final response = await _supabase
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

      await _supabase
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
      await _supabase
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
      final response = await _supabase.from('menu').select('''
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

      await _supabase
          .from('food_addons')
          .insert(addons.map((addon) => addon.toMap()).toList());
    } catch (e) {
      throw Exception('Failed to create addons: $e');
    }
  }

  /// Get all available add-on templates
  Future<List<AddonTemplate>> getAddonTemplates() async {
    try {
      final response = await _supabase
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
