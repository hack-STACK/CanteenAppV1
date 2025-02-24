import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/utils/price_formatter.dart';
import 'package:kantin/widgets/order_details_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:kantin/widgets/rate_menu_dialog.dart';

class EnhancedOrderCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    try {
      if (!_validateItemData(item)) {
        return _buildErrorCard(
          context,
          'Invalid item data',
          'This order item appears to be misconfigured',
        );
      }

      final menuData = _processMenuData(item);
      if (menuData == null) {
        return _buildErrorCard(
          context,
          'Menu data unavailable',
          'Unable to load menu information',
        );
      }

      final processedAddons = _processAddons(item);
      final priceDetails = _calculateSafePrices(item, processedAddons);
      final theme = Theme.of(context);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0, // Remove default elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 20,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 2),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _showOrderDetails(context),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEnhancedHeader(context, menuData),
                  _buildEnhancedContent(context, priceDetails, processedAddons),
                ],
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
    } catch (e, stack) {
      debugPrint('Error building EnhancedOrderCard: $e\n$stack');
      return _buildErrorCard(
        context,
        'Error displaying order',
        'An unexpected error occurred',
      );
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

    return {
      'name': menuData['food_name'] ?? 'Unknown Item',
      'photo': menuData['photo'],
      'description': menuData['description'],
      'preparationTime': menuData['preparation_time']?.toString() ?? '15-20',
      'isSpicy': menuData['is_spicy'] == true,
      'isVegetarian': menuData['is_vegetarian'] == true,
      'calories': menuData['calories']?.toString(),
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

  Widget _buildEnhancedHeader(BuildContext context, Map<String, dynamic> menuData) {
    return Stack(
      children: [
        // Background image with gradient overlay
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildMenuPhoto(menuData['photo']),
        ),
        _buildGradientOverlay(),

        // Content
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadges(context),
                    _buildQuickActions(context),
                  ],
                ),
                
                const Spacer(),
                
                // Bottom info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildInfoChips(context, menuData),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Title and description
                    Text(
                      menuData['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                    if (menuData['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        menuData['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedContent(
    BuildContext context,
    Map<String, dynamic> priceDetails,
    List<Map<String, dynamic>> addons,
  ) {
    // Only show addons section if there are valid addons
    final hasValidAddons = addons.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price section
          _buildEnhancedPriceSection(
            context,
            priceDetails['hasDiscount'],
            priceDetails['originalPrice'],
            priceDetails['discountedPrice'],
            priceDetails['savings'],
          ),

          // Only show addons section if there are valid addons
          if (hasValidAddons) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _buildEnhancedAddonsSection(context, addons),
          ],

          // Notes section
          if (item['notes']?.isNotEmpty == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _buildEnhancedNotesSection(item['notes']),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          
          // Total section
          _buildEnhancedTotalSection(
            context,
            priceDetails['discountedPrice'],
            hasValidAddons ? priceDetails['addonsTotal'] : 0.0,
            priceDetails['finalTotal'],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoChips(BuildContext context, Map<String, dynamic> menuData) {
    return [
      _buildAnimatedInfoChip(
        icon: Icons.schedule,
        label: menuData['preparationTime'],
        suffix: 'min',
        delay: 0,
      ),
      _buildAnimatedInfoChip(
        icon: Icons.shopping_bag_outlined,
        label: (item['quantity'] ?? 1).toString(),
        suffix: 'items',
        delay: 100,
      ),
      if (menuData['calories'] != null)
        _buildAnimatedInfoChip(
          icon: FontAwesomeIcons.fire,
          label: menuData['calories'],
          suffix: 'cal',
          delay: 200,
        ),
    ];
  }

  Widget _buildAnimatedInfoChip({
    required IconData icon,
    required String label,
    String? suffix,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              suffix != null ? '$label $suffix' : label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      delay: Duration(milliseconds: delay),
      duration: 200.ms,
    ).fadeIn(
      delay: Duration(milliseconds: delay),
      duration: 200.ms,
    );
  }

  Widget _buildMenuPhoto(String? photoUrl) {
    if (photoUrl == null) return _buildPlaceholder();
    
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerEffect(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        ),
      ),
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
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
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

  Widget _buildModernHeader(
    BuildContext context, {
    required String menuName,
    String? menuPhoto,
    required int quantity,
    required ThemeData theme,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: menuPhoto != null
                ? CachedNetworkImage(
                    imageUrl: menuPhoto,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => _buildShimmerEffect(),
                    errorWidget: (context, url, error) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
          _buildGradientOverlay(),
          _buildHeaderContent(
            context,
            theme,
            menuName: menuName,
            quantity: quantity,
            description: item['menu']?['description'],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPriceSection(
    BuildContext context,
    bool hasDiscount,
    double originalPrice,
    double discountedPrice,
    double savings,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDiscount ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDiscount ? Colors.red.shade100 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (hasDiscount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer, size: 12, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${((originalPrice - discountedPrice) / originalPrice * 100).round()}% OFF',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDiscount)
                    Text(
                      _formatPrice(originalPrice),
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    _formatPrice(discountedPrice),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hasDiscount ? Colors.red.shade700 : Colors.black87,
                    ),
                  ),
                ],
              ),
              if (savings > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Save ${_formatPrice(savings)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().slideX(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildEnhancedAddonsSection(
    BuildContext context,
    List<Map<String, dynamic>> addons,
  ) {
    if (addons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Add-ons',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...addons.map((addon) {
            final name = addon['addon']?['addon_name'] ?? 'Unknown Add-on';
            final quantity = addon['quantity'] as int? ?? 1;
            final subtotal = addon['subtotal'] as num? ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${quantity}x',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _formatPrice(subtotal.toDouble()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ).animate().slideY(
      begin: 0.2,
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildEnhancedNotesSection(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined,
                  size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              notes,
              style: TextStyle(
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.2,
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildEnhancedTotalSection(
    BuildContext context,
    double basePrice,
    double addonsTotal,
    double finalTotal,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (addonsTotal > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items Subtotal',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  _formatPrice(basePrice),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add-ons Total',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  _formatPrice(addonsTotal),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatPrice(finalTotal),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(
      begin: 0.2,
      delay: const Duration(milliseconds: 500),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildShimmerLoader() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(
    BuildContext context,
    ThemeData theme, {
    required String menuName,
    required int quantity,
    String? description,
  }) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.schedule,
                label: item['menu']?['preparation_time']?.toString() ?? '15-20',
                suffix: 'min',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.shopping_bag_outlined,
                label: quantity.toString(),
                suffix: 'items',
              ),
              if (item['menu']?['calories'] != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: FontAwesomeIcons.fire,
                  label: item['menu']?['calories'].toString() ?? '',
                  suffix: 'cal',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menuName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (ratingData['count'] > 0)
                _buildEnhancedRatingBadge()
                    .animate()
                    .scale(delay: 200.ms, duration: 300.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityBadge(int quantity, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 16, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            '$quantity item${quantity > 1 ? 's' : ''}',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.2, duration: 400.ms);
  }

  Widget _buildStatusIndicators(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Wrap(
        spacing: 8,
        children: [
          if (item['is_new'] == true)
            _buildChip(
              label: 'New',
              color: Colors.blue,
              icon: Icons.fiber_new,
            ),
          if (item['is_popular'] == true)
            _buildChip(
              label: 'Popular',
              color: Colors.orange,
              icon: Icons.trending_up,
            ),
          if (item['menu']?['is_spicy'] == true)
            _buildChip(
              label: 'Spicy',
              color: Colors.red,
              icon: FontAwesomeIcons.pepperHot,
            ),
          if (item['menu']?['is_vegetarian'] == true)
            _buildChip(
              label: 'Veg',
              color: Colors.green,
              icon: FontAwesomeIcons.seedling,
            ),
          if (priceData['hasDiscount']) ...[
            _buildChip(
              label: _calculateDiscountPercentage(),
              color: Colors.purple,
              icon: Icons.local_offer,
            ),
          ],
        ],
      ),
    ).animate().slideX(begin: -0.2, duration: 400.ms);
  }

  String _calculateDiscountPercentage() {
    try {
      final originalPrice = priceData['originalPrice'] as double?;
      final savings = priceData['savings'] as double?;

      if (originalPrice == null || originalPrice == 0 || savings == null) {
        return '0% OFF';
      }

      final percentage = (savings / originalPrice * 100).round();
      return '$percentage% OFF';
    } catch (e) {
      print('Error calculating discount percentage: $e');
      return '0% OFF';
    }
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            onTap: () => _showOrderDetails(context),
            icon: Icons.info_outline,
            tooltip: 'View Details',
          ),
          if (isCompleted && onRatePressed != null)
            _buildActionButton(
              onTap: onRatePressed!,
              icon: Icons.star_outline,
              tooltip: 'Rate Order',
              color: Colors.amber,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String tooltip,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Tooltip(
            message: tooltip,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 20,
                color: color ?? Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    ).animate().scale(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            suffix != null ? '$label $suffix' : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculatePrices(Map<String, dynamic> item) {
    try {
      print('\n============= Transaction Details Debug =============');

      final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 0.0;
      final unitPrice =
          (item['unit_price'] as num?)?.toDouble() ?? originalPrice;
      final discountedPrice =
          (item['discounted_price'] as num?)?.toDouble() ?? unitPrice;
      final discountPercentage =
          (item['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0;
      final quantity = item['quantity'] as int? ?? 1;

      print('\n----- Price Fields from Transaction -----');
      print('Original Price: $originalPrice');
      print('Unit Price: $unitPrice');
      print('Discounted Price: $discountedPrice');
      print('Discount %: $discountPercentage');
      print('Quantity: $quantity');

      final addons = item['addons'] as List<dynamic>? ?? [];
      double addonTotal = 0.0;

      for (final addon in addons) {
        if (addon == null) continue;
        final addonQuantity = addon['quantity'] as int? ?? 0;
        final addonPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
        final addonSubtotal = (addon['subtotal'] as num?)?.toDouble() ??
            (addonQuantity * addonPrice);
        addonTotal += addonSubtotal;
      }

      final totalOriginal = originalPrice * quantity;
      final totalDiscounted = discountedPrice * quantity;
      final savings = originalPrice > 0 ? totalOriginal - totalDiscounted : 0.0;

      final calculatedDiscountPercentage =
          (originalPrice > discountedPrice && originalPrice > 0)
              ? ((originalPrice - discountedPrice) / originalPrice * 100)
                  .clamp(0.0, 100.0)
              : 0.0;

      final result = {
        'hasDiscount': calculatedDiscountPercentage >
            0,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'totalOriginal': totalOriginal,
        'totalDiscounted': totalDiscounted,
        'savings': savings,
        'discountPercentage': calculatedDiscountPercentage,
        'addonTotal': addonTotal,
        'subtotal': totalDiscounted + addonTotal,
      };

      print('Final Result: $result');
      return result;
    } catch (e, stack) {
      print('Error calculating prices: $e\n$stack');
      return {
        'hasDiscount': false,
        'originalPrice': 0.0,
        'discountedPrice': 0.0,
        'totalOriginal': 0.0,
        'totalDiscounted': 0.0,
        'savings': 0.0,
        'discountPercentage': 0.0,
        'addonTotal': 0.0,
        'subtotal': 0.0,
      };
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

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> item) {
    final unitPrice = (item['unit_price'] as num?)?.toDouble();
    final originalPrice =
        (item['original_price'] as num?)?.toDouble() ?? unitPrice ?? 0.0;
    final discountedPrice =
        (item['discounted_price'] as num?)?.toDouble() ?? originalPrice;
    final quantity = item['quantity'] as int? ?? 1;
    final discountPercentage =
        (item['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0;
    final notes = item['notes'] as String?;
    final menuItem = item['menu'] ?? {};
    final menuName = menuItem['food_name'] ?? 'Unknown Item';
    final menuPhoto = menuItem['photo'] as String?;
    final addons = item['addons'] as List<dynamic>? ?? [];

    print('\n=== Order Item Price Debug Info ===');
    print('Unit Price: $unitPrice');
    print('Original Price: $originalPrice');
    print('Discounted Price: $discountedPrice');
    print('Quantity: $quantity');
    print('Discount %: $discountPercentage');
    print('=====================\n');

    final hasDiscount = discountPercentage > 0;
    final savings = (originalPrice - discountedPrice) * quantity;
    final subtotal = discountedPrice * quantity;

    return Card(
      child: Column(
        children: [
          if (addons.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add-ons',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...addons.map((addon) {
                    final addonData = addon['addon'];
                    final addonQuantity = addon['quantity'] as int? ?? 1;
                    final addonPrice =
                        (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
                    final addonSubtotal = addonPrice * addonQuantity;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${addonQuantity}x',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              addonData['addon_name'] ?? 'Unknown Add-on',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            PriceFormatter.format(addonSubtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalSection({
    required double basePrice,
    required double addonsTotal,
    required double finalTotal,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        if (addonsTotal > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add-ons Total',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  _formatPrice(addonsTotal),
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatPrice(finalTotal),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
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

  Widget _buildMenuInfo(BuildContext context, Map<String, dynamic> menuData) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            menuData['name'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 3,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
          if (menuData['description'] != null)
            Text(
              menuData['description'] as String,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadges(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Wrap(
        spacing: 8,
        children: [
          if (item['menu']?['is_new'] == true)
            _buildChip(label: 'New', color: Colors.blue, icon: Icons.fiber_new),
          if (priceData['hasDiscount'] == true)
            _buildChip(
              label: '${priceData['discountPercentage'].round()}% OFF',
              color: Colors.red,
              icon: Icons.local_offer,
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            notes,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (onRatePressed != null)
            TextButton.icon(
              onPressed: onRatePressed,
              icon: const Icon(Icons.star_outline),
              label: const Text('Rate'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.amber,
              ),
            ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showOrderDetails(context),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            '${ratingData['average'].toStringAsFixed(1)} (${ratingData['count']})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
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
          order: order,
          onRefresh: () {
            if (onRatePressed != null) {
              onRatePressed!();
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
}
