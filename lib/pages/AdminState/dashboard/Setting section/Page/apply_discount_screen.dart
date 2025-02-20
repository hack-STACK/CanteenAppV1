import 'package:flutter/material.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/menu_discount.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/services/database/discountService.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ApplyDiscountScreen extends StatefulWidget {
  final Discount discount;
  final int stallId;

  const ApplyDiscountScreen({
    super.key,
    required this.discount,
    required this.stallId,
  });

  @override
  State<ApplyDiscountScreen> createState() => _ApplyDiscountScreenState();
}

class _ApplyDiscountScreenState extends State<ApplyDiscountScreen> {
  final FoodService _foodService = FoodService();
  final DiscountService _discountService = DiscountService();
  final Set<int> _selectedMenuIds = {};
  bool _isLoading = false;
  String? _searchQuery;
  List<Menu>? _allMenus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Apply ${widget.discount.discountName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search menus...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Menu>>(
            future: _foodService.getMenuByStanId(widget.stallId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No menus available'));
              }

              _allMenus ??= snapshot.data;
              final displayedMenus = _filterMenus(_allMenus!, _searchQuery);

              return ListView.builder(
                itemCount: displayedMenus.length,
                itemBuilder: (context, index) {
                  final menu = displayedMenus[index];
                  return _buildMenuTile(menu);
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedMenuIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _applyDiscount,
              label: Text(
                _isLoading
                    ? 'Applying...'
                    : 'Apply to ${_selectedMenuIds.length} items',
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
            )
          : null,
    );
  }

  List<Menu> _filterMenus(List<Menu> menus, String? query) {
    if (query == null || query.isEmpty) return menus;
    return menus
        .where((menu) =>
            menu.foodName.toLowerCase().contains(query.toLowerCase()) ||
            (menu.description?.toLowerCase() ?? '').contains(query)) // Fix null check here
        .toList();
  }

  Widget _buildMenuTile(Menu menu) {
    final isSelected = _selectedMenuIds.contains(menu.id);
    final discountedPrice =
        menu.price * (1 - widget.discount.discountPercentage / 100);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: menu.photo != null
              ? CachedNetworkImage(
                  imageUrl: menu.photo!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[200],
                  child: Icon(
                    menu.type == 'food' ? Icons.restaurant : Icons.local_drink,
                    color: Colors.grey,
                  ),
                ),
        ),
        title: Text(menu.foodName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelected) ...[
              Text(
                'Original: Rp ${menu.price.toStringAsFixed(0)}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Discounted: Rp ${discountedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else
              Text('Rp ${menu.price.toStringAsFixed(0)}'),
          ],
        ),
        trailing: Checkbox(
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
        ),
        onTap: () {
          setState(() {
            if (_selectedMenuIds.contains(menu.id)) {
              _selectedMenuIds.remove(menu.id);
            } else {
              _selectedMenuIds.add(menu.id!);
            }
          });
        },
      ),
    );
  }

  Future<void> _applyDiscount() async {
    if (_selectedMenuIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one menu item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int successCount = 0;
      int errorCount = 0;
      final List<String> errors = [];
      final now = DateTime.now();

      for (final menuId in _selectedMenuIds) {
        try {
          await _discountService.addMenuDiscount(
            MenuDiscount(
              id: 0,
              menuId: menuId,
              discountId: widget.discount.id,
              isActive: true, // Add this argument
            ),
          );
          successCount++;
        } catch (e) {
          errorCount++;
          if (!errors.contains(e.toString())) {
            errors.add(e.toString());
          }
          continue;
        }
      }

      if (mounted) {
        if (errorCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Successfully applied discount to $successCount items'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Applied to $successCount items with $errorCount failures\n${errors.join("\n")}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.pop(context, true);
        } else {
          _showErrorDialog(
            'Failed to apply discounts',
            errors.join("\n"),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Error',
          'Failed to apply discount: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
