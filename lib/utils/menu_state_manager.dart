import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';

class MenuStateManager {
  final Map<int, List<Menu>> _menusByType = {};
  final Map<int, List<FoodAddon>> _addonsByMenu = {};

  void updateMenus(List<Menu> menus) {
    _menusByType.clear();

    // Group menus by type
    for (final menu in menus) {
      final type = _getMenuTypeId(menu.type);
      _menusByType[type] = [..._menusByType[type] ?? [], menu];
    }
  }

  void updateAddons(Map<int, List<FoodAddon>> addons) {
    _addonsByMenu.clear();
    _addonsByMenu.addAll(addons);
  }

  List<Menu> getMenusByType(String type) {
    final typeId = _getMenuTypeId(type);
    return _menusByType[typeId] ?? [];
  }

  List<FoodAddon> getAddonsForMenu(int menuId) {
    return _addonsByMenu[menuId] ?? [];
  }

  int _getMenuTypeId(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return 1;
      case 'drink':
        return 2;
      default:
        return 0;
    }
  }

  void clear() {
    _menusByType.clear();
    _addonsByMenu.clear();
  }
}
