import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/services/database/foodService.dart';

class MenuSelectionDialog extends StatefulWidget {
  final Discount discount;
  final List<Menu> availableMenus;
  final List<int> selectedMenuIds;
  final Function(List<int>) onMenusSelected;

  const MenuSelectionDialog({
    super.key,
    required this.discount,
    required this.availableMenus,
    required this.selectedMenuIds,
    required this.onMenusSelected,
  });

  @override
  State<MenuSelectionDialog> createState() => _MenuSelectionDialogState();
}

class _MenuSelectionDialogState extends State<MenuSelectionDialog> {
  late List<int> _selectedMenuIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedMenuIds = List.from(widget.selectedMenuIds);
  }

  List<Menu> get _filteredMenus {
    return widget.availableMenus.where((menu) {
      return menu.foodName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select Menus for ${widget.discount.discountName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search menus...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_selectedMenuIds.length} items selected'),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selectedMenuIds.length ==
                              widget.availableMenus.length) {
                            _selectedMenuIds.clear();
                          } else {
                            _selectedMenuIds = widget.availableMenus
                                .map((m) => m.id!)
                                .toList();
                          }
                        }),
                        child: Text(
                          _selectedMenuIds.length ==
                                  widget.availableMenus.length
                              ? 'Deselect All'
                              : 'Select All',
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _filteredMenus[index];
                        final isSelected = _selectedMenuIds.contains(menu.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedMenuIds.add(menu.id!);
                              } else {
                                _selectedMenuIds.remove(menu.id!);
                              }
                            });
                          },
                          title: Text(menu.foodName),
                          subtitle: Text(
                            'Original Price: Rp ${menu.price.toStringAsFixed(0)}\n'
                            'After Discount: Rp ${(menu.price * (1 - widget.discount.discountPercentage / 100)).toStringAsFixed(0)}',
                          ),
                          secondary: menu.photo != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(menu.photo!),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onMenusSelected(_selectedMenuIds);
                    Navigator.pop(context);
                  },
                  child: Text('Apply Discount'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
