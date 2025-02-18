import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';

class StallDetailPage extends StatefulWidget {
  final Stan stall;

  const StallDetailPage({Key? key, required this.stall}) : super(key: key);

  @override
  State<StallDetailPage> createState() => _StallDetailPageState();
}

class _StallDetailPageState extends State<StallDetailPage> {
  final Map<String, int> _cartItems = {};
  final FoodService _foodService = new FoodService();
  List<Menu> _menus = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      final menus = await _foodService.getMenuByStanId(widget.stall.id);
      if (mounted) {
        setState(() {
          _menus = menus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading menus: $e')),
        );
      }
    }
  }

  void _addToCart(String itemName, double price) {
    setState(() {
      _cartItems[itemName] = (_cartItems[itemName] ?? 0) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $itemName to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stall.stanName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // TODO: Implement cart view
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMenus,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner Image
              if (widget.stall.Banner_img != null)
                Image.network(
                  widget.stall.Banner_img!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),

              // Stall Information
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stall Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: widget.stall.imageUrl != null
                              ? NetworkImage(widget.stall.imageUrl!)
                              : const AssetImage('assets/default_stall.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.stall.stanName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text('Owner: ${widget.stall.ownerName}'),
                              Text('Phone: ${widget.stall.phone}'),
                              Text('Location: ${widget.stall.slot}'),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.stall.description),

                    const SizedBox(height: 24),

                    // Menu Section
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_menus.isEmpty)
                      const Center(
                        child: Text(
                          'No menu items available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _menus.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final menu = _menus[index];
                          return ListTile(
                            leading: menu.photo != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      menu.photo!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      menu.type == 'food'
                                          ? Icons.restaurant
                                          : Icons.local_drink,
                                      color: Colors.grey,
                                    ),
                                  ),
                            title: Text(menu.foodName),
                            subtitle: Text(menu.description),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Rp ${menu.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: menu.isAvailable
                                      ? () =>
                                          _addToCart(menu.foodName, menu.price)
                                      : null,
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _cartItems.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement checkout
                  },
                  child: const Text('Proceed to Checkout'),
                ),
              ),
            )
          : null,
    );
  }
}
