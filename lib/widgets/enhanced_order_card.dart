import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/utils/price_formatter.dart';
import 'package:kantin/widgets/order_details_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kantin/Services/rating_service.dart';
import 'dart:ui';

class EnhancedOrderCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> order;
  final Map<String, dynamic> priceData;
  final Map<String, dynamic> ratingData;
  final bool isCompleted;
  final VoidCallback? onRatePressed;

  const EnhancedOrderCard({
    super.key,
    required this.item,
    required this.order,
    required this.priceData,
    required this.ratingData,
    required this.isCompleted,
    this.onRatePressed,
  });

  @override
  State<EnhancedOrderCard> createState() => _EnhancedOrderCardState();
}

class _EnhancedOrderCardState extends State<EnhancedOrderCard> with SingleTickerProviderStateMixin {
  bool _isRated = false;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _checkRatingStatus();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkRatingStatus() async {
    if (!widget.isCompleted) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final menuId = widget.item['menu']?['id'] ?? 
                     widget.item['menu_id'] ?? 
                     widget.item['menuData']?['id'];
      // Safely convert transaction ID to int if it's a string
      final rawTransactionId = widget.order['id'];
      final transactionId = rawTransactionId is String ? int.tryParse(rawTransactionId) : rawTransactionId;

      if (menuId != null && transactionId != null) {
        final hasRated = await RatingService().hasUserRatedMenu(
          menuId is String ? int.tryParse(menuId.toString()) ?? 0 : menuId,
          transactionId is String ? int.tryParse(transactionId.toString()) ?? 0 : transactionId as int,
        );
        
        if (mounted) {
          setState(() {
            _isRated = hasRated;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error checking rating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (!_validateItemData(widget.item)) {
        return _buildErrorCard(
          context,
          'Invalid item data',
          'This order item appears to be misconfigured',
        );
      }

      final menuData = _processMenuData(widget.item);
      if (menuData == null) {
        return _buildErrorCard(
          context,
          'Menu data unavailable',
          'Unable to load menu information',
        );
      }

      final processedAddons = _processAddons(widget.item);
      final priceDetails = _calculateSafePrices(widget.item, processedAddons);
      final theme = Theme.of(context);
      final hasDiscount = priceDetails['hasDiscount'] == true;

      // Enhanced modern card design
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) {
              _animationController.reverse();
              _showOrderDetails(context);
            },
            onTapCancel: () => _animationController.reverse(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Enhanced image header with stacked elements
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      // Hero image
                      _buildMenuImage(menuData['photo']),
                      
                      // Premium gradient overlay
                      _buildEnhancedGradientOverlay(),
                      
                      // Status indicator - top right
                      if (widget.order['status'] != null) 
                        _buildStatusBadge(widget.order['status']),
                      
                      // Discount badge - if applicable
                      if (hasDiscount) 
                        _buildDiscountBadge(priceDetails),
                      
                      // Title and stall info
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Item name with enhanced typography
                            Text(
                              menuData['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            // Stall name
                            if (menuData['stallName'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storefront,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      menuData['stallName'],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Enhanced content area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and quantity row with improved layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price display with proper hierarchy
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Price values
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      _formatPrice(priceDetails['discountedPrice']),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: hasDiscount ? theme.colorScheme.error : theme.colorScheme.primary,
                                      ),
                                    ),
                                    if (hasDiscount) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatPrice(priceDetails['originalPrice']),
                                        style: TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Enhanced quantity indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_basket,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${priceDetails['quantity']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Order date
                      if (widget.order['created_at'] != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateTime(DateTime.parse(widget.order['created_at'])),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      
                      // Divider before addons
                      if (processedAddons.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _buildEnhancedAddonsSection(processedAddons),
                      ],
                      
                      // Notes section with improved styling
                      if (widget.item['notes']?.isNotEmpty == true) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notes, size: 16, color: Colors.amber[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.item['notes'],
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.amber[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Order summary - only show in detailed view
                      if (priceDetails['savings'] > 0 || priceDetails['addonsTotal'] > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              // Item subtotal row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item subtotal:',
                                    style: TextStyle(
                                      fontSize: 13, 
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    _formatPrice(priceDetails['baseTotal']),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Addons total row
                              if (priceDetails['addonsTotal'] > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Add-ons:',
                                      style: TextStyle(
                                        fontSize: 13, 
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      _formatPrice(priceDetails['addonsTotal']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              // Savings row
                              if (priceDetails['savings'] > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.savings_outlined,
                                          size: 14,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'You saved:',
                                          style: TextStyle(
                                            fontSize: 13, 
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatPrice(priceDetails['savings']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              // Divider before total
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Divider(height: 1),
                              ),
                              
                              // Total row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 14, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatPrice(priceDetails['finalTotal']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Enhanced rate button for completed orders
                if (widget.isCompleted && widget.onRatePressed != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ElevatedButton.icon(
                      onPressed: widget.onRatePressed,
                      icon: Icon(
                        _isRated ? Icons.star : Icons.star_outline,
                        size: 18,
                      ),
                      label: Text(_isRated ? 'View Your Rating' : 'Rate This Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRated ? Colors.amber : theme.colorScheme.primaryContainer,
                        foregroundColor: _isRated ? Colors.white : theme.colorScheme.primary,
                        elevation: _isRated ? 0 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ).animate()
       .fadeIn(duration: 400.ms, curve: Curves.easeOut)
       .slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuint);
    } catch (e, stack) {
      debugPrint('Error building EnhancedOrderCard: $e\n$stack');
      return _buildErrorCard(
        context,
        'Error displaying order',
        'An unexpected error occurred',
      );
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String label;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = Colors.orange;
        label = 'Pending';
        icon = Icons.pending;
        break;
      case 'confirmed':
        badgeColor = Colors.blue;
        label = 'Confirmed';
        icon = Icons.check_circle_outline;
        break;
      case 'cooking':
        badgeColor = Colors.amber;
        label = 'Cooking';
        icon = Icons.restaurant;
        break;
      case 'delivering':
        badgeColor = Colors.purple;
        label = 'Delivering';
        icon = Icons.delivery_dining;
        break;
      case 'ready':
        badgeColor = Colors.green;
        label = 'Ready';
        icon = Icons.check_circle;
        break;
      case 'completed':
        badgeColor = Colors.green[700]!;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        badgeColor = Colors.grey;
        label = 'Unknown';
        icon = Icons.help_outline;
    }

    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountBadge(Map<String, dynamic> priceDetails) {
    // Calculate discount percentage
    final originalPrice = priceDetails['originalPrice'] as double;
    final discountedPrice = priceDetails['discountedPrice'] as double;
    final discountPercent = ((originalPrice - discountedPrice) / originalPrice * 100).round();

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[700]!, Colors.red[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$discountPercent% OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuImage(String? photoUrl) {
    return SizedBox(
      height: 140, // Reduced height for better performance and less space
      width: double.infinity,
      child: _buildSafeImage(photoUrl),
    );
  }

  // Create a safer image builder method
  Widget _buildSafeImage(String? photoUrl) {
    // Better validation for image URLs
    final bool hasValidImageUrl = photoUrl != null && 
                                photoUrl.trim().isNotEmpty && 
                                (photoUrl.startsWith('http://') || 
                                 photoUrl.startsWith('https://') || 
                                 photoUrl.startsWith('data:image/'));
    
    if (!hasValidImageUrl) {
      return _buildPlaceholder();
    }
    
    return CachedNetworkImage(
      imageUrl: photoUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildShimmerEffect(),
      errorWidget: (context, url, error) {
        debugPrint('Image error: $error for URL: $url');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildEnhancedGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.6),
            ],
            stops: const [0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedAddonsSection(List<Map<String, dynamic>> addons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.add_circle_outline, size: 14),
            const SizedBox(width: 6),
            Text(
              'Add-ons',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: addons.map((addon) {
              final name = addon['addon']?['addon_name'] ?? 'Unknown Add-on';
              final quantity = addon['quantity'] as int? ?? 1;
              final subtotal = addon['subtotal'] as num? ?? 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$quantity×',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      _formatPrice(subtotal.toDouble()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ... existing code for validation, processing, and calculations ...

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    // Ensure order ID is properly handled if it's not a string
    final orderId = widget.order['id'];
    final orderWithSafeId = {
      ...widget.order,
      'id': orderId is int ? orderId.toString() : orderId,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => OrderDetailsSheet(
          order: orderWithSafeId,
          onRefresh: () {
            if (widget.onRatePressed != null) {
              widget.onRatePressed!();
            }
          },
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }
  
  String _formatDateTime(DateTime dateTime) {
    // Convert to local time if it's in UTC
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final orderDate = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
    
    if (orderDate == today) {
      return 'Today, ${DateFormat('HH:mm').format(localDateTime)}';
    } else if (orderDate == yesterday) {
      return 'Yesterday, ${DateFormat('HH:mm').format(localDateTime)}';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(localDateTime);
    }
  }
  
  bool _validateItemData(Map<String, dynamic> item) {
    return item.isNotEmpty && 
           item['menu'] != null &&
           item['quantity'] != null;
  }

  Map<String, dynamic>? _processMenuData(Map<String, dynamic> item) {
    final menuData = item['menu'];
    if (menuData == null) return null;

    // Convert IDs to strings if they're not already
    final menuId = menuData['id'];
    final menuIdStr = menuId?.toString() ?? 'N/A';

    return {
      'id': menuIdStr,
      'name': menuData['food_name'] ?? 'Unknown Item',
      'photo': menuData['photo'],
      'description': menuData['description'],
      'stallName': menuData['stall']?['nama_stalls'] ?? 'Unknown Stall',
    };
  }

  Map<String, dynamic> _calculateSafePrices(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> addons,
  ) {
    try {
      final quantity = item['quantity'] as int? ?? 1;
      final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 0.0;
      final discountedPrice = (item['discounted_price'] as num?)?.toDouble() ?? originalPrice;
      
      final baseTotal = discountedPrice * quantity;
      final addonsTotal = _calculateAddonTotal(addons);
      final savings = ((originalPrice - discountedPrice) * quantity).abs();
      
      return {
        'hasDiscount': discountedPrice < originalPrice,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'quantity': quantity,
        'baseTotal': baseTotal,
        'addonsTotal': addonsTotal,
        'finalTotal': baseTotal + addonsTotal,
        'savings': savings,
      };
    } catch (e) {
      debugPrint('Error calculating prices: $e');
      return {
        'hasDiscount': false,
        'originalPrice': 0.0,
        'discountedPrice': 0.0,
        'quantity': 1,
        'baseTotal': 0.0,
        'addonsTotal': 0.0,
        'finalTotal': 0.0,
        'savings': 0.0,
      };
    }
  }

  List<Map<String, dynamic>> _processAddons(Map<String, dynamic> item) {
    try {
      // Handle single addon case
      if (item['addon_name'] != null && item['addon_price'] != null) {
        // Only return if there's valid addon data
        if (item['addon_name'].toString().isNotEmpty && 
            (item['addon_price'] as num?)?.toDouble() != 0.0) {
          return [{
            'addon': {
              'addon_name': item['addon_name'],
              'price': item['addon_price']
            },
            'quantity': item['addon_quantity'] ?? 1,
            'unit_price': item['addon_price'] ?? 0.0,
            'subtotal': item['addon_subtotal'] ?? 
                ((item['addon_price'] ?? 0.0) * (item['addon_quantity'] ?? 1)),
          }];
        }
      }

      // Handle array of addons
      final addonsData = item['addons'] as List<dynamic>? ?? [];
      return addonsData.where((addon) {
        // Filter out invalid or empty addons
        if (addon is! Map<String, dynamic>) return false;
        final name = addon['addon']?['addon_name'];
        final price = (addon['unit_price'] as num?)?.toDouble();
        return name != null && 
               name.toString().isNotEmpty && 
               price != null && 
               price > 0;
      }).map((addon) => addon as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error processing addons: $e');
      return [];
    }
  }

  double _calculateAddonTotal(List<dynamic> addons) {
    if (addons.isEmpty) return 0.0;

    return addons.fold<double>(
      0.0,
      (sum, addon) {
        final subtotal = (addon['subtotal'] as num?)?.toDouble();
        if (subtotal != null) return sum + subtotal;

        final quantity = addon['quantity'] as int? ?? 0;
        final unitPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
        return sum + (quantity * unitPrice);
      },
    );
  }
}

// Define DeliveryType enum to avoid conflicts with transaction_enums.dart
enum DeliveryType {
  pickup,
  delivery,
  dine_in,
}

// Define OrderTypeData class if not already defined
class OrderTypeData {
  final DeliveryType type;
  final IconData icon;
  final Color color;
  final String label;

  OrderTypeData({
    required this.type,
    required this.icon,
    required this.color,
    required this.label,
  });
}
