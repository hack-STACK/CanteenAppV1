import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Services/Database/Stan_service.dart'; // Add this import
import 'package:kantin/Services/rating_service.dart';
import 'package:kantin/utils/avatar_generator.dart';
import 'dart:async'; // Add this import for Timer

class AnimatedStallTile extends StatefulWidget {
  // Keep existing properties
  final Stan stall;
  final VoidCallback onTap;
  final bool useHero;
  final String? openingHours;
  final bool? isCurrentlyOpenBySchedule;
  // Add optional refresh interval
  final Duration? refreshInterval;

  const AnimatedStallTile({
    super.key,
    required this.stall,
    required this.onTap,
    this.useHero = false,
    this.openingHours,
    this.isCurrentlyOpenBySchedule,
    this.refreshInterval, // Add this parameter
  });

  @override
  State<AnimatedStallTile> createState() => _AnimatedStallTileState();
}

class _AnimatedStallTileState extends State<AnimatedStallTile>
    with SingleTickerProviderStateMixin {
  final _ratingService = RatingService();
  final _stallService = StanService(); // Add service instance
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Add variables for database status
  bool _isDbStatusLoaded = false;
  bool? _dbStallStatus;
  Timer? _refreshTimer;
  String? _nextOpeningInfo;

  // Add this as a new field in the _AnimatedStallTileState class
  List<Discount>? _activeDiscounts;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Fetch initial status
    _fetchStallStatus();
    
    // Add this line to fetch promotion info
    _fetchPromotionInfo();

    // Setup timer for periodic refresh if interval is provided
    if (widget.refreshInterval != null) {
      _refreshTimer = Timer.periodic(widget.refreshInterval!, (_) {
        if (mounted) {
          _fetchStallStatus();
          _fetchPromotionInfo(); // Add this line to periodically refresh promotions
        }
      });
    }
  }

  // Add method to fetch stall status from database
  Future<void> _fetchStallStatus() async {
    try {
      final isOpen = await _stallService.checkIfStoreIsOpenNow(widget.stall.id);

      // If the stall is closed, also fetch the next opening time
      String nextOpening = '';
      if (!isOpen) {
        nextOpening = await _stallService.getNextOpeningInfo(widget.stall.id);
      }

      if (mounted) {
        setState(() {
          _dbStallStatus = isOpen;
          _isDbStatusLoaded = true;
          if (!isOpen) {
            _nextOpeningInfo = nextOpening;
          }
        });
      }
    } catch (e) {
      print('Error fetching stall status: $e');
      // On error, fall back to local calculation
      if (mounted) {
        setState(() {
          _isDbStatusLoaded = false;
        });
      }
    }
  }

  // Add this new method after _fetchStallStatus()
  Future<void> _fetchPromotionInfo() async {
    try {
      // Check for active promotions for this stall
      final discounts = await _stallService.getActiveDiscounts(widget.stall.id);
      
      if (mounted) {
        setState(() {
          // Store discounts in local state instead of trying to modify the Stan object
          _activeDiscounts = discounts;
        });
      }
      
      print('Fetched ${discounts.length} active promotions for stall ${widget.stall.id}');
    } catch (e) {
      print('Error fetching promotion info: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Add this method to determine the actual status, considering database status first
  bool _getStallOpenStatus() {
    // First priority: Use database status if available
    if (_isDbStatusLoaded && _dbStallStatus != null) {
      return _dbStallStatus!;
    }
    // Second priority: Use provided schedule status
    else if (widget.isCurrentlyOpenBySchedule != null) {
      return widget.isCurrentlyOpenBySchedule!;
    }
    // Fallback: Calculate locally
    else {
      return widget.stall.isScheduleOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the new method to determine open status
    final bool isOpen = _getStallOpenStatus();

    // Rest of the build method...
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final imageWidth = maxWidth * 0.28;

            return GestureDetector(
              // Existing gesture detector code...
              onTapDown: (_) {
                setState(() => _isPressed = true);
                _controller.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _controller.reverse();
                widget.onTap();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _controller.reverse();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.05),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSection(imageWidth),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderSection(),
                                  const SizedBox(height: 6),
                                  _buildRatingSection(),
                                  const SizedBox(height: 8),
                                  _buildInfoSection(),
                                  if (widget.openingHours != null)
                                    Text(
                                      widget.openingHours!,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  // Add next opening info if available
                                  if (!isOpen &&
                                      _nextOpeningInfo != null &&
                                      _nextOpeningInfo!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.update,
                                              size: 12, color: Colors.orange),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Opens $_nextOpeningInfo',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.orange[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isOpen) _buildClosedOverlay(),
                      // Add database status indicator if available
                      if (_isDbStatusLoaded)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Keep existing widget methods
  Widget _buildImageSection(double width) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.useHero
                  ? Hero(tag: 'stall_${widget.stall.id}', child: _buildImage())
                  : _buildImage(),
            ),
            if (widget.stall.isBusy)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BUSY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.stall.stanName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                _getCuisineTypeDisplay(widget.stall.cuisineType),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusBadges(),
          ],
        ),
      ],
    );
  }

  String _getCuisineTypeDisplay(String? cuisineType) {
    if (cuisineType == null || cuisineType.isEmpty) {
      return 'Mixed Dishes • Local Food';
    }

    // Convert first letter of each word to uppercase
    return cuisineType.split(' ').map((word) {
      if (word.isNotEmpty) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }
      return word;
    }).join(' ');
  }

  Widget _buildStatusBadges() {
    // Modify to consider database status
    final bool isOpen = _getStallOpenStatus();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOpen)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[300]!],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: Colors.green[50],
                ),
                const SizedBox(width: 4),
                const Text(
                  'OPEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        if (widget.stall.hasActivePromotions()) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[300]!],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.red[300]!.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_offer,
                  size: 8,
                  color: Colors.red[50],
                ),
                const SizedBox(width: 4),
                const Text(
                  'PROMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _ratingService.getStallRatings(widget.stall.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildRatingShimmer();
        }

        if (snapshot.hasError) {
          print('Rating error for stall ${widget.stall.id}: ${snapshot.error}');
          return _buildRatingDisplay(0.0, 0);
        }

        final rating = snapshot.data?['average'] ?? 0.0;
        final reviewCount = snapshot.data?['count'] ?? 0;

        print(
            'Debug: Stall ${widget.stall.id} rating data: $rating, count: $reviewCount');

        return _buildRatingDisplay(rating, reviewCount);
      },
    );
  }

  Widget _buildRatingDisplay(double rating, int reviewCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 12, color: Colors.amber[700]),
              const SizedBox(width: 4),
              Text(
                reviewCount > 0 ? rating.toStringAsFixed(1) : 'New',
                style: TextStyle(
                  color: Colors.amber[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingShimmer() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 12, color: Colors.grey[300]),
              const SizedBox(width: 4),
              Container(
                width: 24,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    // Check if using default schedule
    bool isUsingDefaultSchedule = widget.openingHours != null &&
        widget.openingHours!.contains('(Default)');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildInfoChip(
          icon: Icons.access_time,
          text: _formatTimeOfDay(widget.stall.openTime),
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        _buildInfoChip(
          icon: Icons.location_on,
          text: '${widget.stall.distance?.toStringAsFixed(0) ?? "?"} m',
          gradient: LinearGradient(
            colors: [Colors.green[100]!, Colors.green[50]!],
          ),
        ),
        // Add indicator for default schedule if applicable
        if (isUsingDefaultSchedule)
          _buildInfoChip(
            icon: Icons.schedule,
            text: 'Default Hours',
            gradient: LinearGradient(
              colors: [Colors.orange[100]!, Colors.orange[50]!],
            ),
          ),
      ],
    );
  }

  Widget _buildClosedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[800],
                ),
                const SizedBox(width: 8),
                Text(
                  'CLOSED',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[800]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.stall.imageUrl == null || widget.stall.imageUrl!.isEmpty) {
      return AvatarGenerator.generateStallAvatar(widget.stall.stanName);
    }

    // Check if the URL is valid and has a proper scheme
    Uri? uri;
    try {
      uri = Uri.parse(widget.stall.imageUrl!);
      if (!uri.hasScheme) {
        return AvatarGenerator.generateStallAvatar(widget.stall.stanName);
      }
    } catch (e) {
      return AvatarGenerator.generateStallAvatar(widget.stall.stanName);
    }

    return Image.network(
      widget.stall.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        return AvatarGenerator.generateStallAvatar(widget.stall.stanName);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'N/A';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Add this static method for easy creation of next opening info widget
  static Widget nextOpeningInfo(Stan stall, String nextOpeningTime) {
    if (nextOpeningTime.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(Icons.update, size: 12, color: Colors.orange[700]),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Opens $nextOpeningTime',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to manually refresh stall status
  Future<void> refreshStatus() async {
    await _fetchStallStatus();
  }
}
