import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final priceData = _calculatePrices(widget.item);

    // Debug the calculated prices
    print('\n=== Price Calculation Debug ===');
    print('Price Data: $priceData');
    print('============================\n');

    // Debug transaction details data
    print('\n=== Transaction Details Debug ===');
    // print('Item data: ${widget.item}');
    print('Original price from transaction: ${widget.item['original_price']}');
    print(
        'Discounted price from transaction: ${widget.item['discounted_price']}');
    print(
        'Applied discount % from transaction: ${widget.item['applied_discount_percentage']}');
    print('Quantity: ${widget.item['quantity']}');

    // Get stored discount info from transaction_details with safety checks
    final originalPrice = (widget.item['original_price'] as num?)?.toDouble();
    final discountedPrice =
        (widget.item['discounted_price'] as num?)?.toDouble();
    final discountPercentage =
        (widget.item['applied_discount_percentage'] as num?)?.toDouble();
    final quantity = widget.item['quantity'] as int? ?? 1;

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

    // Create price data object with correct types
    final updatedPriceData = {
      'hasDiscount': savings > 0,
      'originalPrice': validOriginalPrice,
      'discountedPrice': validDiscountedPrice,
      'totalOriginal': totalOriginal,
      'totalDiscounted': totalDiscounted,
      'savings': savings,
      'discountPercentage': validDiscountPercentage,
    };

    final theme = Theme.of(context);
    final addons = widget.item['addons'] as List<dynamic>? ?? [];
    final menuName = widget.item['menu']?['food_name'] ?? 'Unknown Item';
    final menuPhoto = widget.item['menu']?['photo'];

    return Hero(
      tag: 'order_${widget.order['id']}',
      child: AnimationConfiguration.staggeredList(
        position: widget.order['id'] as int,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Material(
              // Add Material widget for ripple effect
              color: Colors.transparent,
              child: InkWell(
                // Add InkWell for tap feedback
                onTap: () => _showOrderDetails(context),
                splashColor: Colors.blue.withOpacity(0.3),
                highlightColor: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.2)), // Debug border
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            hasDiscount:
                                updatedPriceData['hasDiscount'] as bool,
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
          ),
        ),
      ),
    );
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
    print('\n=== Enhanced Content Debug ===');
    print('Has Discount: $hasDiscount');
    print('Original Price: $originalPrice');
    print('Discounted Price: $discountedPrice');
    print('Savings: $savings');
    print('============================\n');

    // Calculate discount percentage here instead of accessing priceData
    final discountPercentage = hasDiscount
        ? ((originalPrice - discountedPrice) / originalPrice * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDiscount) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Applied Discount: $discountPercentage%',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original price: ${_formatPrice(originalPrice)} → ${_formatPrice(discountedPrice)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'You saved: ${_formatPrice(savings)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (addons.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildModernAddonsSection(addons),
          ],
          const SizedBox(height: 16),
          _buildModernTotalSection(theme, discountedPrice),
          if (widget.isCompleted) ...[
            const SizedBox(height: 16),
            _buildModernActionButtons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[200],
      child: Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
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
          const Text(
            'Add-ons',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ...addons.map((addon) {
            // Get values directly from transaction_addon_details
            final quantity = addon['quantity'] as int? ?? 1;
            final unitPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
            final subtotal = (addon['subtotal'] as num?)?.toDouble() ??
                (quantity * unitPrice);
            final name = addon['addon']?['addon_name'] ?? 'Unknown Add-on';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    '${quantity}x',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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

  Widget _buildModernTotalSection(ThemeData theme, double total) {
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
          _formatPrice(total),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
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
          if (widget.priceData['hasDiscount'])
            _buildChip(
              label:
                  '${((widget.priceData['savings'] / widget.priceData['originalPrice']) * 100).round()}% OFF',
              color: Colors.purple,
              icon: Icons.local_offer,
            ),
        ],
      ),
    ).animate().slideX(begin: -0.2, duration: 400.ms);
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
      // Debug header
      print('\n============= Transaction Details Debug =============');

      // Menu Item Debug Section
      print('\n----- Main Menu Item -----');
      print('Menu ID: ${item['menu']?['id']}');
      print('Menu Name: ${item['menu']?['food_name']}');
      print('Base Menu Price: ${item['menu']?['price']}');

      // Get all price fields with proper null handling
      final menuPrice = (item['menu']?['price'] as num?)?.toDouble() ?? 0.0;
      final originalPrice = item['original_price'] != null
          ? double.parse(item['original_price'].toString())
          : menuPrice;
      final unitPrice = item['unit_price'] != null
          ? double.parse(item['unit_price'].toString())
          : originalPrice;
      final discountedPrice = item['discounted_price'] != null
          ? double.parse(item['discounted_price'].toString())
          : unitPrice;
      final discountPercentage = item['applied_discount_percentage'] != null
          ? double.parse(item['applied_discount_percentage'].toString())
          : ((originalPrice - unitPrice) / originalPrice * 100);
      final quantity = item['quantity'] as int? ?? 1;

      print('\n----- Price Calculations -----');
      print('Original Price: $originalPrice');
      print('Unit Price: $unitPrice');
      print('Discounted Price: $discountedPrice');
      print('Discount %: $discountPercentage');
      print('Quantity: $quantity');

      // Calculate main item totals
      final totalOriginal = originalPrice * quantity;
      final totalDiscounted = discountedPrice * quantity;
      final savings = totalOriginal - totalDiscounted;

      print('\n----- Main Item Totals -----');
      print('Total Original: $totalOriginal');
      print('Total Discounted: $totalDiscounted');
      print('Savings: $savings');

      // Addons Debug Section
      print('\n----- Add-ons Details -----');
      final addons = item['addon_items'] as List<dynamic>? ?? [];
      double addonTotal = 0.0;

      if (addons.isEmpty) {
        print('No add-ons for this item');
      } else {
        print('Found ${addons.length} add-ons:');
      }

      for (final addon in addons) {
        print('\nAdd-on: ${addon['addon']?['addon_name']}');
        final addonQuantity = addon['quantity'] as int? ?? 0;
        final addonPrice = (addon['unit_price'] as num?)?.toDouble() ?? 0.0;
        final addonSubtotal = (addon['subtotal'] as num?)?.toDouble() ??
            (addonQuantity * addonPrice);

        print('  Quantity: $addonQuantity');
        print('  Unit Price: $addonPrice');
        print('  Subtotal: $addonSubtotal');

        addonTotal += addonSubtotal;
      }

      print('\n----- Final Calculations -----');
      final result = {
        'hasDiscount': discountPercentage > 0,
        'originalPrice': originalPrice,
        'discountedPrice': discountedPrice,
        'totalOriginal': totalOriginal + addonTotal,
        'totalDiscounted': totalDiscounted + addonTotal,
        'savings': savings,
        'discountPercentage': discountPercentage,
        'addonTotal': addonTotal,
        'unitPrice': unitPrice,
        'subtotal': discountedPrice * quantity + addonTotal,
      };

      print('Total with Add-ons: ${result['totalDiscounted']}');
      print('Total Add-ons: $addonTotal');
      print('Final Subtotal: ${result['subtotal']}');
      print('==============================================\n');

      return result;
    } catch (e, stack) {
      print('\n!!! Error calculating prices !!!');
      print('Error: $e');
      print('Stack trace: $stack');
      print('==============================================\n');

      return {
        'hasDiscount': false,
        'originalPrice': 0.0,
        'discountedPrice': 0.0,
        'totalOriginal': 0.0,
        'totalDiscounted': 0.0,
        'savings': 0.0,
        'discountPercentage': 0.0,
        'addonTotal': 0.0,
        'unitPrice': 0.0,
        'subtotal': 0.0,
      };
    }
  }
}
