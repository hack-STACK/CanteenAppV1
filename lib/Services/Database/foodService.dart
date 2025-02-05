import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// **🔵 Create: Insert a new menu item**
  Future<void> createMenu(Menu menu) async {
    try {
      // Check if menu already exists
      final existingMenu = await _supabase
          .from('menu')
          .select()
          .eq('food_name', menu.foodName)
          .maybeSingle();

      if (existingMenu != null) {
        // Update if exists
        await _supabase
            .from('menu')
            .update(menu.toJson(excludeId: true))
            .eq('food_name', menu.foodName);
      } else {
        // Insert if new
        await _supabase.from('menu').insert(menu.toJson(excludeId: true));
      }
    } catch (e) {
      throw Exception('Failed to insert/update menu: $e');
    }
  }

  /// **🔵 Create: Insert a new food add-on**
  Future<void> createFoodAddon(FoodAddon addon) async {
    final response = await _supabase.from('food_addons').insert(addon.toJson());
    if (response.error != null) {
      throw Exception('Failed to insert addon: ${response.error!.message}');
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

  /// **🟢 Read: Get all food add-ons for a specific menu**
  Future<List<FoodAddon>> getAddonsForMenu(int menuId) async {
    final response =
        await _supabase.from('food_addons').select().eq('menu_id', menuId);
    return response.map<FoodAddon>((json) => FoodAddon.fromJson(json)).toList();
  }

  /// **🟡 Update: Update a menu item**
  Future<void> updateMenu(Menu menu) async {
    await _supabase.from('menu').update(menu.toJson()).eq('id', menu.id!);
  }

  /// **🟡 Update: Update a food add-on**
  Future<void> updateFoodAddon(FoodAddon addon) async {
    await _supabase
        .from('food_addons')
        .update(addon.toJson())
        .eq('id', addon.id);
  }

  /// **🔴 Delete: Remove a menu item**
  Future<void> deleteMenu(int id) async {
    await _supabase.from('menu').delete().eq('id', id);
  }

  /// **🔴 Delete: Remove a food add-on**
  Future<void> deleteFoodAddon(int id) async {
    await _supabase.from('food_addons').delete().eq('id', id);
  }
}
