import 'dart:async';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Services/Database/foodService.dart';

class StoreService {
  final FoodService _foodService;
  final _menuController = StreamController<List<Menu>>.broadcast();
  final _addonController =
      StreamController<Map<int, List<FoodAddon>>>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();

  // Improve caching with last update timestamp
  final Map<int, List<Menu>> _menuCache = {};
  final Map<int, List<FoodAddon>> _addonCache = {};
  DateTime? _lastUpdate;
  static const _cacheTimeout = Duration(minutes: 5);

  StoreService(this._foodService);

  Stream<List<Menu>> get menuStream => _menuController.stream;
  Stream<Map<int, List<FoodAddon>>> get addonStream => _addonController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;

  void _setLoading(bool value) => _loadingController.add(value);

  bool _isCacheValid() {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < _cacheTimeout;
  }

  Future<void> loadMenusForStore(int storeId) async {
    if (_isCacheValid()) {
      // Use cached data if valid
      _menuController.add(_menuCache[storeId] ?? []);
      final addonMap = Map<int, List<FoodAddon>>.from(_addonCache);
      _addonController.add(addonMap);
      return;
    }

    try {
      _setLoading(true);
      final menus = await _foodService.getMenuByStanId(storeId);
      _menuCache[storeId] = menus;
      _menuController.add(menus);

      // Load add-ons in parallel
      final addonFutures = <Future<void>>[];
      final Map<int, List<FoodAddon>> addonMap = {};

      for (final menu in menus) {
        addonFutures.add(
          _foodService.getAddonsForMenu(menu.id).then((addons) {
            addonMap[menu.id] = addons;
            _addonCache[menu.id] = addons;
          }),
        );
      }

      await Future.wait(addonFutures);
      _lastUpdate = DateTime.now();
      _addonController.add(addonMap);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveAddon(FoodAddon addon) async {
    try {
      _setLoading(true);

      // Update or create addon
      final savedAddon = addon.id != null
          ? await _foodService.updateFoodAddon(addon)
          : await _foodService.createFoodAddon(addon);

      // Update local cache without reloading everything
      final currentAddons = _addonCache[addon.menuId] ?? [];
      final addonIndex = currentAddons.indexWhere((a) => a.id == addon.id);

      if (addonIndex >= 0) {
        currentAddons[addonIndex] = savedAddon;
      } else {
        currentAddons.add(savedAddon);
      }

      _addonCache[addon.menuId] = currentAddons;

      // Update stream without triggering a full reload
      final currentAddonMap = Map<int, List<FoodAddon>>.from(_addonCache);
      _addonController.add(currentAddonMap);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAddon(int menuId, int addonId) async {
    try {
      _setLoading(true);

      // Update cache optimistically
      final currentAddons = _addonCache[menuId] ?? [];
      currentAddons.removeWhere((addon) => addon.id == addonId);
      _addonCache[menuId] = currentAddons;

      // Update stream
      final currentAddonMap = Map<int, List<FoodAddon>>.from(_addonCache);
      _addonController.add(currentAddonMap);

      // Perform deletion
      await _foodService.deleteFoodAddon(addonId);
    } catch (e) {
      // Revert cache on error
      await loadMenusForStore(menuId);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearCache() {
    _menuCache.clear();
    _addonCache.clear();
    _lastUpdate = null;
  }

  void dispose() {
    _menuController.close();
    _addonController.close();
    _loadingController.close();
    clearCache();
  }
}
