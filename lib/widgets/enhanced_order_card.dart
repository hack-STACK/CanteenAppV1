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

class _EnhancedOrderCardState extends State<EnhancedOrderCard> {
  final _ratingService = RatingService();
  bool _hasRated = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkRatingStatus();
  }

  Future<void> _checkRatingStatus() async {
    if (!widget.isCompleted) {
      setState(() => _isChecking = false);
      return;
    }

    try {
      final menuId = widget.item['menu']?['id'];
      final transactionId = widget.order['id'];

      if (menuId != null && transactionId != null) {
        final hasRated =
            await _ratingService.hasUserRatedMenu(menuId, transactionId);
        if (mounted) {
          setState(() {
            _hasRated = hasRated;
            _isChecking = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _handleRatePressed() {
    if (_hasRated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already rated this item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final menuData = {
      'id': widget.item['menu']?['id'],
      'menu_name': widget.item['menu']?['food_name'] ?? 'Unknown Item',
      'stall': widget.item['menu']?['stall'],
      'transaction_id': widget.order['id'],
      'photo': widget.item['menu']?['photo'],
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateMenuDialog(
        menuId: menuData['id'],
        stallId: menuData['stall']?['id'],
        transactionId: menuData['transaction_id'],
        menuName: menuData['menu_name'],
        menuPhoto: menuData['photo'],
        onRatingSubmitted: () {
          setState(() => _hasRated = true);
          widget.onRatePressed?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add null checks and default values
    final safeItem = widget.item;
    if (safeItem == null) {
      return const SizedBox();
    }

    final theme = Theme.of(context);
    final menuName = safeItem['menu']?['food_name'] ?? 'Unknown Item';
    final menuPhoto = safeItem['menu']?['photo'];
    final quantity = safeItem['quantity'] as int? ?? 1;

    // Debug logs
    print('\n=== EnhancedOrderCard Debug ===');
    print('Item Data: ${widget.item}');
    print('Price Data: ${widget.priceData}');
    print('Rating Data: ${widget.ratingData}');
    print('===========================\n');

    // Debug transaction details data
    print('\n=== Transaction Details Debug ===');
    print('Original price from transaction: ${safeItem['original_price']}');
    print('Discounted price from transaction: ${safeItem['discounted_price']}');
    print(
        'Applied discount % from transaction: ${safeItem['applied_discount_percentage']}');
    print('Quantity: ${safeItem['quantity']}');

    // Get stored discount info from transaction_details with safety checks
    final originalPrice = (safeItem['original_price'] as num?)?.toDouble();
    final discountedPrice = (safeItem['discounted_price'] as num?)?.toDouble();
    final discountPercentage =
        (safeItem['applied_discount_percentage'] as num?)?.toDouble();

    print('Parsed values:');
    print('Original Price: $originalPrice');
    print('Discounted Price: $discountedPrice');
    print('Discount %: $discountPercentage');
    print('==============================\n');

    // Validate and provide fallbacks for prices
    final validOriginalPrice = originalPrice ?? 0.0;
    final validDiscountedPrice = discountedPrice ?? validOriginalPrice;
    final validDiscountPercentage = discountPercentage ?? 0.0;

    // Calculate totals based on stored values
    final totalOriginal = validOriginalPrice * quantity;
    final totalDiscounted = validDiscountedPrice * quantity;
    final savings = totalOriginal - totalDiscounted;

    // Create updated price data object with correct types
    final updatedPriceData = {
      'hasDiscount': savings > 0,
      'originalPrice': validOriginalPrice,
      'discountedPrice': validDiscountedPrice,
      'totalOriginal': totalOriginal,
      'totalDiscounted': totalDiscounted,
      'savings': savings,
      'discountPercentage': validDiscountPercentage,
    };

    final addons = widget.item['addons'] as List<dynamic>? ?? [];

    // Replace the Hero and AnimationConfiguration with this simpler structure
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(context),
          splashColor: Colors.blue.withOpacity(0.3),
          highlightColor: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildModernHeader(
                      context,
                      menuName: menuName,
                      menuPhoto: menuPhoto,
                      quantity: quantity,
                      theme: theme,
                    ),
                    _buildEnhancedContent(
                      context,
                      hasDiscount: updatedPriceData['hasDiscount'] as bool,
                      originalPrice:
                          updatedPriceData['originalPrice'] as double,
                      discountedPrice:
                          updatedPriceData['discountedPrice'] as double,
                      savings: updatedPriceData['savings'] as double,
                      addons: addons,
                      theme: theme,
                    ),
                  ],
                ),
                _buildStatusIndicators(context),
                _buildQuickActions(context),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2);
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
            description: widget.item['menu']?['description'],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedContent(
    BuildContext context, {
    required bool hasDiscount,
    required double originalPrice,
    required double discountedPrice,
    required double savings,
    required List<dynamic> addons,
    required ThemeData theme,
  }) {
    // Cast the addons list to the correct type
    final List<Map<String, dynamic>> typedAddons = addons.map((addon) {
      if (addon is Map<String, dynamic>) {
        return addon;
      }
      // If the addon is not already a Map<String, dynamic>, convert it
      return Map<String, dynamic>.from(addon as Map);
    }).toList();

    // Only show discount if there's an actual price difference
    final bool showDiscount = hasDiscount &&
        savings > 0 &&
        originalPrice > discountedPrice &&
        discountedPrice > 0;

    final discountPercentage = showDiscount
        ? ((originalPrice - discountedPrice) / originalPrice * 100).round()
        : 0;

    // Calculate totals
    final double basePrice = showDiscount ? discountedPrice : originalPrice;
    final double totalAddons = _calculateAddonTotal(addons);
    final double finalTotal = basePrice + totalAddons;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Section with Optional Discount
          _buildPriceSection(
            showDiscount: showDiscount,
            originalPrice: originalPrice,
            discountedPrice: discountedPrice,
            discountPercentage: discountPercentage,
          ),

          // Add-ons Section if present
          if (addons.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildAddonsSection(typedAddons),
          ],

          // Total Section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildTotalSection(
            basePrice: basePrice,
            addonsTotal: totalAddons,
            finalTotal: finalTotal,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection({
    required bool showDiscount,
    required double originalPrice,
    required double discountedPrice,
    required int discountPercentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showDiscount) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_offer,
                            size: 12, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$discountPercentage% OFF',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showDiscount)
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: showDiscount ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddonsSection(List<Map<String, dynamic>> addons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add-ons',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ...addons.map((addon) {
          final addonData = addon['addon'];
          final quantity = addon['quantity'] as int? ?? 1;
          final unitPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
          final subtotal = (addon['subtotal'] as num?)?.toDouble() ?? 0.0;
          final name = addonData['addon_name'] ?? 'Unknown Add-on';

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
                    '${quantity}x',
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
                    name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  'Rp ${subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEnhancedPriceSection(
    double originalPrice,
    double discountedPrice,
    double savings,
    ThemeData theme,
  ) {
    final savePercentage =
        ((originalPrice - discountedPrice) / originalPrice * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer,
                        size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '$savePercentage% OFF',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatPrice(originalPrice),
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'You save ${_formatPrice(savings)}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 400.ms);
  }

  Widget _buildModernAddonsSection(List<dynamic> addons) {
    if (addons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Add-ons',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Map each add-on
          ...addons.map((addon) {
            // Extract addon data
            final addonData = addon['addon'] ?? {};
            final quantity = addon['quantity'] as int? ?? 1;
            final unitPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
            final subtotal = (addon['subtotal'] as num?)?.toDouble() ??
                (quantity * unitPrice);
            final name = addonData['addon_name'] ?? 'Unknown Add-on';

            // Build addon row
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Quantity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade100,
                      ),
                    ),
                    child: Text(
                      '${quantity}x',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add-on name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (unitPrice > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${_formatPrice(unitPrice)} each',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Subtotal
                  Text(
                    _formatPrice(subtotal),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms);
  }

  Widget _buildModernTotalSection(
    ThemeData theme,
    double basePrice, [
    List<dynamic>? addons,
  ]) {
    if (addons == null || addons.isEmpty) {
      // Simple total without addons
      return Row(
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
            _formatPrice(basePrice),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      );
    }

    // Calculate total with addons
    final addonTotal = addons.fold<double>(
      0.0,
      (sum, addon) => sum + ((addon['subtotal'] as num?)?.toDouble() ?? 0.0),
    );

    final total = basePrice + addonTotal;

    return Column(
      children: [
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
                _formatPrice(addonTotal),
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
              _formatPrice(total),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.isCompleted)
          _isChecking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(
                    _hasRated ? Icons.star : Icons.star_border,
                    color: _hasRated ? Colors.amber : null,
                  ),
                  onPressed: _hasRated ? null : _handleRatePressed,
                  tooltip: _hasRated ? 'Already rated' : 'Rate this item',
                ),
      ],
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
            '${widget.ratingData['average'].toStringAsFixed(1)} (${widget.ratingData['count']})',
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
          order: widget.order,
          onRefresh: () {
            // Provide a non-nullable callback
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
                label: widget.item['menu']?['preparation_time']?.toString() ??
                    '15-20',
                suffix: 'min',
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.shopping_bag_outlined,
                label: quantity.toString(),
                suffix: 'items',
              ),
              if (widget.item['menu']?['calories'] != null) ...[
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: FontAwesomeIcons.fire,
                  label: widget.item['menu']?['calories'].toString() ?? '',
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
              if (widget.ratingData['count'] > 0)
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
          if (widget.item['is_new'] == true)
            _buildChip(
              label: 'New',
              color: Colors.blue,
              icon: Icons.fiber_new,
            ),
          if (widget.item['is_popular'] == true)
            _buildChip(
              label: 'Popular',
              color: Colors.orange,
              icon: Icons.trending_up,
            ),
          if (widget.item['menu']?['is_spicy'] == true)
            _buildChip(
              label: 'Spicy',
              color: Colors.red,
              icon: FontAwesomeIcons.pepperHot,
            ),
          if (widget.item['menu']?['is_vegetarian'] == true)
            _buildChip(
              label: 'Veg',
              color: Colors.green,
              icon: FontAwesomeIcons.seedling,
            ),
          if (widget.priceData['hasDiscount']) ...[
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

  // Add this helper method to safely calculate the discount percentage
  String _calculateDiscountPercentage() {
    try {
      final originalPrice = widget.priceData['originalPrice'] as double?;
      final savings = widget.priceData['savings'] as double?;

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
          if (widget.isCompleted)
            _buildActionButton(
              onTap: _handleRatePressed,
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

      // Ensure we have valid numbers, defaulting to 0.0 if null
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

      // Calculate addons total with null safety
      final addons = item['addons'] as List<dynamic>? ?? [];
      double addonTotal = 0.0;

      for (final addon in addons) {
        if (addon == null) continue; // Skip null addons
        final addonQuantity = addon['quantity'] as int? ?? 0;
        final addonPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
        final addonSubtotal = (addon['subtotal'] as num?)?.toDouble() ??
            (addonQuantity * addonPrice);
        addonTotal += addonSubtotal;
      }

      // Ensure we don't divide by zero
      final totalOriginal = originalPrice * quantity;
      final totalDiscounted = discountedPrice * quantity;
      final savings = originalPrice > 0 ? totalOriginal - totalDiscounted : 0.0;

      // Only calculate discount percentage if there's an actual price difference
      final calculatedDiscountPercentage =
          (originalPrice > discountedPrice && originalPrice > 0)
              ? ((originalPrice - discountedPrice) / originalPrice * 100)
                  .clamp(0.0, 100.0)
              : 0.0;

      final result = {
        'hasDiscount': calculatedDiscountPercentage >
            0, // Only true if there's an actual discount
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
      // Return safe default values if calculation fails
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
        // Use subtotal from transaction_addon_details if available
        final subtotal = (addon['subtotal'] as num?)?.toDouble();
        if (subtotal != null) return sum + subtotal;

        // Otherwise calculate from quantity and unit_price
        final quantity = addon['quantity'] as int? ?? 0;
        final unitPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
        return sum + (quantity * unitPrice);
      },
    );
  }

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> item) {
    // Extract the unit price directly from the transaction details
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

    // Add debug logging for price calculations
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
      // ... existing card UI code ...
      child: Column(
        children: [
          // ... existing menu item display code ...

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
}
