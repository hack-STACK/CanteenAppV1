import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Services/Database/foodService.dart';

class TopMenuSection extends StatefulWidget {
  final String title;
  final List<String> filterOptions;
  final int itemCount;
  final Color accentColor;
  final VoidCallback? onSeeAllTap;
  final FoodService foodService;
  final int? stanid;

  const TopMenuSection(
      {super.key,
      this.title = 'Top menus',
      this.filterOptions = const ['Latest', 'Popular', 'Trending'],
      this.itemCount = 3,
      this.accentColor = const Color(0xFFFF542D),
      this.onSeeAllTap,
      required this.foodService,
      required List<Menu> menus,
      required this.stanid});

  @override
  State<TopMenuSection> createState() => _TopMenuSectionState();
}

class _TopMenuSectionState extends State<TopMenuSection> {
  late final ValueNotifier<String> _selectedFilter;
  late final ValueNotifier<bool> _isExpanded;
  late final ValueNotifier<bool> _isLoading;
  late final ValueNotifier<List<Menu>> _menus;
  final Map<int, List<FoodAddon>> _menuAddons = {};

  @override
  void initState() {
    super.initState();
    _selectedFilter = ValueNotifier(widget.filterOptions.first);
    _isExpanded = ValueNotifier(false);
    _isLoading = ValueNotifier(true);
    _menus = ValueNotifier([]);

    _fetchMenus();
  }

  @override
  void dispose() {
    _selectedFilter.dispose();
    _isExpanded.dispose();
    _isLoading.dispose();
    _menus.dispose();
    super.dispose();
  }

  Future<void> _fetchMenus() async {
    try {
      _isLoading.value = true;
      // Use the stan_id to fetch menus
      final menus = await widget.foodService.getMenuByStanId(widget.stanid);

      final sortedMenus = _sortMenus(menus);
      final limitedMenus = _limitMenus(sortedMenus);
      await _fetchAddons(limitedMenus);

      _menus.value = limitedMenus;
    } catch (e) {
      debugPrint('Error fetching menus: $e');
      _menus.value = [];
    } finally {
      _isLoading.value = false;
    }
  }

  List<Menu> _sortMenus(List<Menu> menus) {
    switch (_selectedFilter.value) {
      case 'Latest':
        return menus..sort((a, b) => b.id!.compareTo(a.id!));
      case 'Popular':
        // Implement popular sorting logic
        return menus;
      case 'Trending':
        // Implement trending sorting logic
        return menus;
      default:
        return menus;
    }
  }

  List<Menu> _limitMenus(List<Menu> menus) {
    return widget.itemCount > 0 ? menus.take(widget.itemCount).toList() : menus;
  }

  Future<void> _fetchAddons(List<Menu> menus) async {
    for (final menu in menus) {
      if (menu.id != null) {
        _menuAddons[menu.id!] =
            await widget.foodService.getAddonsForMenu(menu.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TopMenuHeader(
            title: widget.title,
            accentColor: widget.accentColor,
            onSeeAllTap: widget.onSeeAllTap,
            selectedFilter: _selectedFilter,
            isExpanded: _isExpanded,
            onFilterChanged: (filter) {
              _selectedFilter.value = filter;
              _isExpanded.value = false;
              _fetchMenus();
            },
            filterOptions: widget.filterOptions,
          ),
          const SizedBox(height: 16),
          _TopMenuContent(
            isLoading: _isLoading,
            menus: _menus,
            menuAddons: _menuAddons,
            accentColor: widget.accentColor,
            isExpanded: _isExpanded,
            selectedFilter: _selectedFilter,
            onFilterSelect: (filter) {
              _selectedFilter.value = filter;
              _isExpanded.value = false;
              _fetchMenus();
            },
            filterOptions: widget.filterOptions,
          ),
        ],
      ),
    );
  }
}

class _TopMenuHeader extends StatelessWidget {
  final String title;
  final Color accentColor;
  final VoidCallback? onSeeAllTap;
  final ValueNotifier<String> selectedFilter;
  final ValueNotifier<bool> isExpanded;
  final Function(String) onFilterChanged;
  final List<String> filterOptions;

  const _TopMenuHeader({
    required this.title,
    required this.accentColor,
    required this.onSeeAllTap,
    required this.selectedFilter,
    required this.isExpanded,
    required this.onFilterChanged,
    required this.filterOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Discover your favorite meals',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Figtree',
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterDropdown(
                selectedFilter: selectedFilter,
                isExpanded: isExpanded,
                accentColor: accentColor,
              ),
              if (onSeeAllTap != null) ...[
                const SizedBox(width: 8),
                _SeeAllButton(
                  onTap: onSeeAllTap!,
                  accentColor: accentColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final ValueNotifier<String> selectedFilter;
  final ValueNotifier<bool> isExpanded;
  final Color accentColor;

  const _FilterDropdown({
    required this.selectedFilter,
    required this.isExpanded,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedFilter,
      builder: (context, filter, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isExpanded,
          builder: (context, expanded, _) {
            return Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 80,
                  minHeight: 36,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha((0.08 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => isExpanded.value = !expanded,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          filter,
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          expanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 20,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;

  const _SeeAllButton({
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(60, 36),
      ),
      child: const Text(
        'See all',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _TopMenuContent extends StatelessWidget {
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<List<Menu>> menus;
  final Map<int, List<FoodAddon>> menuAddons;
  final Color accentColor;
  final ValueNotifier<bool> isExpanded;
  final ValueNotifier<String> selectedFilter;
  final Function(String) onFilterSelect;
  final List<String> filterOptions;

  const _TopMenuContent({
    required this.isLoading,
    required this.menus,
    required this.menuAddons,
    required this.accentColor,
    required this.isExpanded,
    required this.selectedFilter,
    required this.onFilterSelect,
    required this.filterOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withAlpha((0.15 * 255).toInt()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: isExpanded,
        builder: (context, expanded, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expanded)
                _FilterOptions(
                  filterOptions: filterOptions,
                  selectedFilter: selectedFilter,
                  accentColor: accentColor,
                  onFilterSelect: onFilterSelect,
                ),
              ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, _) {
                  if (loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ValueListenableBuilder<List<Menu>>(
                    valueListenable: menus,
                    builder: (context, menuList, _) {
                      if (menuList.isEmpty) {
                        return const Center(child: Text('No menus found'));
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: menuList.length,
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          return _MenuCard(
                            menu: menuList[index],
                            addons: menuAddons[menuList[index].id] ?? [],
                            accentColor: accentColor,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Menu menu;
  final List<FoodAddon> addons;
  final Color accentColor;

  const _MenuCard({
    required this.menu,
    required this.addons,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MenuImage(
              imageUrl: menu.photo,
              type: menu.type,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MenuDetails(
                menu: menu,
                addons: addons,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuImage extends StatelessWidget {
  final String imageUrl;
  final String type;

  const _MenuImage({
    required this.imageUrl,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: Icon(
            type == 'food' ? Icons.restaurant : Icons.local_drink,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _MenuDetails extends StatelessWidget {
  final Menu menu;
  final List<FoodAddon> addons;
  final Color accentColor;

  const _MenuDetails({
    required this.menu,
    required this.addons,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = menu.type == 'food' ? Colors.orange : Colors.blue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                menu.foodName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: typeColor.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                menu.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: typeColor[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          menu.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rp ${menu.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            if (addons.isNotEmpty) _AddonsChip(count: addons.length),
          ],
        ),
      ],
    );
  }
}

class _AddonsChip extends StatelessWidget {
  final int count;

  const _AddonsChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count Add-ons',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _FilterOptions extends StatelessWidget {
  final List<String> filterOptions;
  final ValueNotifier<String> selectedFilter;
  final Color accentColor;
  final Function(String) onFilterSelect;

  const _FilterOptions({
    required this.filterOptions,
    required this.selectedFilter,
    required this.accentColor,
    required this.onFilterSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: selectedFilter,
        builder: (context, selected, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: filterOptions.map((filter) {
              final isSelected = filter == selected;
              return InkWell(
                onTap: () => onFilterSelect(filter),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withAlpha((0.08 * 255).toInt())
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? accentColor : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
