import 'package:flutter/material.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/pages/StudentState/payment_page.dart';
import 'package:provider/provider.dart';

enum CartState { loading, empty, error, ready }

class FoodCartPage extends StatefulWidget {
  const FoodCartPage({super.key, required this.StudentId});
  final int StudentId;

  @override
  State<FoodCartPage> createState() => _FoodCartPageState();
}

class _FoodCartPageState extends State<FoodCartPage> {
  CartState _cartState = CartState.loading;
  String? _errorMessage;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCart();
    // Initialize address from Restaurant provider
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    _addressController.text = restaurant.deliveryAddress;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _initializeCart() async {
    try {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      setState(() => _cartState = CartState.loading);

      // Simulate network delay for demonstration
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _cartState =
            restaurant.cart.isEmpty ? CartState.empty : CartState.ready;
      });
    } catch (e) {
      setState(() {
        _cartState = CartState.error;
        _errorMessage = 'Failed to load cart: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (_cartState == CartState.ready)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(context),
              tooltip: 'Clear Cart',
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    switch (_cartState) {
      case CartState.loading:
        return const Center(child: CircularProgressIndicator());

      case CartState.empty:
        return _buildEmptyCart();

      case CartState.error:
        return _buildErrorState();

      case CartState.ready:
        return _buildCartItems();
    }
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to start your order',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializeCart,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) {
        return CustomScrollView(
          slivers: [
            // Add delivery address section
            SliverToBoxAdapter(
              child: _buildDeliveryAddressSection(restaurant),
            ),
            // Order Summary
            SliverToBoxAdapter(
              child: _buildOrderSummary(restaurant),
            ),

            // Cart Items
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child:
                        _buildCartItemCard(restaurant.cart[index], restaurant),
                  ),
                  childCount: restaurant.cart.length,
                ),
              ),
            ),

            // Additional Notes
            SliverToBoxAdapter(
              child: _buildNotesSection(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderSummary(Restaurant restaurant) {
    final totalItems = restaurant.cart.length;
    final subtotal = restaurant.calculateSubtotal();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$totalItems ${totalItems == 1 ? 'item' : 'items'}'),
                Text(
                  'Rp ${subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, Restaurant restaurant) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.menu.photo != null
                      ? Image.network(
                          item.menu.photo!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: Icon(
                            item.menu.type == 'food'
                                ? Icons.restaurant
                                : Icons.local_drink,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.menu.foodName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.selectedAddons.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Add-ons: ${item.selectedAddons.map((a) => a.addonName).join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (item.note?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${item.note}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quantity Controls
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(item, false, restaurant),
                      icon: const Icon(Icons.remove_circle_outline),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQuantity(item, true, restaurant),
                      icon: const Icon(Icons.add_circle_outline),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rp ${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        'Rp ${(item.totalPrice / item.quantity).toStringAsFixed(0)} each',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add notes for the restaurant...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 100), // Bottom padding for scroll
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) {
        if (_cartState != CartState.ready) return const SizedBox.shrink();

        final subtotal = restaurant.calculateSubtotal();

        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(
                    'Rp ${subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _proceedToCheckout(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Proceed to Checkout'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateQuantity(CartItem item, bool increase, Restaurant restaurant) {
    try {
      if (increase) {
        restaurant.increaseQuantity(item);
      } else {
        restaurant.decreaseQuantity(item);
      }

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            increase ? 'Quantity increased' : 'Quantity decreased',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating quantity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showClearCartDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      restaurant.clearCart();
      setState(() => _cartState = CartState.empty);
    }
  }

  void _proceedToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          StudentId: widget.StudentId,
        ),
      ),
    );
  }

  // Add this method to show address picker
  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Enter your location',
                  hintText: 'e.g., Ruang 32, Gedung A',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final restaurant = Provider.of<Restaurant>(
                        context,
                        listen: false,
                      );
                      restaurant.updateDeliveryAddress(_addressController.text);
                      Navigator.pop(context);
                    },
                    child: Text('Save Location'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressSection(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Delivery Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showAddressPicker,
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.deliveryAddress,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
