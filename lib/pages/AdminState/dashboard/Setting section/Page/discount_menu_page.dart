import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/services/database/discountService.dart';

class DiscountMenuPage extends StatefulWidget {
  final Discount discount;
  final int stallId;

  const DiscountMenuPage({
    super.key,
    required this.discount,
    required this.stallId,
  });

  @override
  State<DiscountMenuPage> createState() => _DiscountMenuPageState();
}

class _DiscountMenuPageState extends State<DiscountMenuPage> {
  final FoodService _foodService = FoodService();
  final DiscountService _discountService = DiscountService();
  bool _isLoading = true;
  List<Menu> _menus = [];
  Set<int> _appliedMenuIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load all menus for this stall
      final menus = await _foodService.getMenuByStanId(widget.stallId);

      // Load menu-discount relationships for each menu
      final appliedDiscounts = <int>{};
      for (final menu in menus) {
        if (menu.id != null) {
          final menuDiscounts =
              await _discountService.getMenuDiscountsByMenuId(menu.id!);
          if (menuDiscounts.any(
              (md) => md.discountId == widget.discount.id && md.isActive)) {
            appliedDiscounts.add(menu.id!);
          }
        }
      }

      if (mounted) {
        setState(() {
          _menus = menus;
          _appliedMenuIds = appliedDiscounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Items - ${widget.discount.discountName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMenuList(),
    );
  }

  Widget _buildMenuList() {
    if (_menus.isEmpty) {
      return const Center(child: Text('No menu items available'));
    }

    return ListView.builder(
      itemCount: _menus.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final menu = _menus[index];
        final hasDiscount = _appliedMenuIds.contains(menu.id);
        final discountedPrice =
            menu.price * (1 - widget.discount.discountPercentage / 100);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _buildMenuImage(menu),
            title: Text(menu.foodName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original: Rp ${menu.price.toStringAsFixed(0)}'),
                if (hasDiscount)
                  Text(
                    'With Discount: Rp ${discountedPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Switch(
              value: hasDiscount,
              onChanged: (value) => _toggleDiscount(menu, value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuImage(Menu menu) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: menu.photo != null
          ? CachedNetworkImage(
              imageUrl: menu.photo!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 56,
                height: 56,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => _buildMenuPlaceholder(menu),
            )
          : _buildMenuPlaceholder(menu),
    );
  }

  Widget _buildMenuPlaceholder(Menu menu) {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[200],
      child: Icon(
        menu.type == 'food' ? Icons.restaurant : Icons.local_drink,
        color: Colors.grey,
      ),
    );
  }

  Future<void> _toggleDiscount(Menu menu, bool value) async {
    try {
      setState(() => _isLoading = true);

      await _discountService.updateMenuDiscount(
        menu.id!,
        widget.discount.id,
        value,
      );

      setState(() {
        if (value) {
          _appliedMenuIds.add(menu.id!);
        } else {
          _appliedMenuIds.remove(menu.id!);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Discount ${value ? 'applied to' : 'removed from'} ${menu.foodName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
