import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Models/menu_cart_item.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/pages/StudentState/payment_page.dart';
import 'package:provider/provider.dart';
import 'package:kantin/widgets/badges/discount_badge.dart';

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
  final StudentService _studentService = StudentService();
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _initializeCart();
    _loadStudentAddress();
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

  Future<void> _loadStudentAddress() async {
    try {
      final student = await _studentService.getStudentById(widget.StudentId);
      if (student != null && mounted) {
        final restaurant = Provider.of<Restaurant>(context, listen: false);
        restaurant.updateDeliveryAddress(student.studentAddress);
        _addressController.text = student.studentAddress;
      }
    } catch (e) {
      debugPrint('Error loading student address: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shopping_basket_rounded),
            const SizedBox(width: 8),
            Text('Your Cart', style: theme.textTheme.titleLarge),
          ],
        ),
        actions: [
          if (_cartState == CartState.ready)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearCartDialog(context),
              tooltip: 'Clear Cart',
            ).animate().scale(),
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
    // Add debug print at the start of the method
    debugPrint('''
=== Discount Debug for ${item.menu.foodName} ===
Original Price: ${item.originalPrice}
Discounted Price: ${item.discountedPrice}
Has Discount: ${item.hasDiscount}
Discount Percentage: ${((item.originalPrice - item.discountedPrice) / item.originalPrice * 100)}
===================================
''');

    return Dismissible(
      key: ValueKey(item.menu.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
      ),
      onDismissed: (direction) {
        restaurant.removeFromCart(item);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${item.menu.foodName} removed from cart'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () => restaurant.addToCart(
                  item.menu,
                  quantity: item.quantity,
                  addons: item.selectedAddons,
                  note: item.note,
                ),
              ),
            ),
          );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main Content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section with Hero animation
                  Hero(
                    tag: 'cart_item_${item.menu.id}',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: item.menu.photo ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.restaurant),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Base Price
                          Text(
                            item.menu.foodName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Price Section with discount if applicable
                          Row(
                            children: [
                              if (item.hasDiscount &&
                                  item.discountedPrice <
                                      item.originalPrice) ...[
                                Text(
                                  'Rp ${item.originalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rp ${item.discountedPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ] else
                                Text(
                                  'Rp ${item.originalPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),

                          // Add-ons Section
                          if (item.selectedAddons.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: item.selectedAddons.map((addon) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 12,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        addon.addonName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          // Note Section
                          if (item.note?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.note_alt_outlined,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.note!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Quantity Controls
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Quantity Selector
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    _buildQuantityButton(
                                      icon: Icons.remove,
                                      onPressed: () => _updateQuantity(
                                          item, false, restaurant),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    _buildQuantityButton(
                                      icon: Icons.add,
                                      onPressed: () => _updateQuantity(
                                          item, true, restaurant),
                                    ),
                                  ],
                                ),
                              ),

                              // Total Price
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
                                      '${item.quantity}x @ Rp ${(item.totalPrice / item.quantity).toStringAsFixed(0)}',
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
                  ),
                ],
              ),
              // Add discount badge if item has discount
              if (item.originalPrice > item.discountedPrice)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DiscountBadge(
                    discountPercentage:
                        ((item.originalPrice - item.discountedPrice) /
                            item.originalPrice *
                            100),
                    compact: true,
                  ),
                ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16),
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
        final itemCount = restaurant.cart.length;

        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -4),
                blurRadius: 16,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _proceedToCheckout(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn().moveY(begin: 50, end: 0);
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
    // Get cart items with addons
    final restaurant = Provider.of<Restaurant>(context, listen: false);

    // Debug log cart items
    print('\n=== Cart Debug Before Checkout ===');
    for (var item in restaurant.cart) {
      print('Menu: ${item.menu.foodName}');
      print('Price: ${item.menu.price}');
      print('Addons: ${item.selectedAddons.length}');
      for (var addon in item.selectedAddons) {
        print('  - ${addon.addonName}: ${addon.price}');
      }
    }
    print('===========================\n');

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
                decoration: const InputDecoration(
                  labelText: 'Enter your location',
                  hintText: 'e.g., Ruang 32, Gedung A',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Please provide a delivery address',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final newAddress = _addressController.text.trim();
                      try {
                        final restaurant = Provider.of<Restaurant>(
                          context,
                          listen: false,
                        );
                        restaurant.updateDeliveryAddress(newAddress);
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Location'),
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
      color: restaurant.deliveryAddress.trim().isEmpty
          ? Colors.red.shade50
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on,
                    color: restaurant.deliveryAddress.trim().isEmpty
                        ? Colors.red
                        : Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivery Location (Required)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddressPicker,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (restaurant.deliveryAddress.trim().isEmpty)
              const Text(
                'Please enter a delivery address',
                style: TextStyle(color: Colors.red),
              )
            else
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
