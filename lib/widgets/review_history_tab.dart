import 'package:flutter/material.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:intl/intl.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/widgets/rating_indicator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

class ReviewHistoryTab extends StatefulWidget {
  final int studentId;
  // Add the onReviewTap callback parameter
  final Function(Map<String, dynamic>)? onReviewTap;

  const ReviewHistoryTab({
    super.key, 
    required this.studentId, 
    this.onReviewTap,  // Optional callback when a review is tapped
  });

  @override
  State<ReviewHistoryTab> createState() => _ReviewHistoryTabState();
}

class _ReviewHistoryTabState extends State<ReviewHistoryTab> with SingleTickerProviderStateMixin {
  final RatingService _ratingService = RatingService();
  final Logger _logger = Logger('ReviewHistoryTab');
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _reviews = [];
  String? _error;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadReviews();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reviews = await _ratingService.getFilteredReviews(
        studentId: widget.studentId,
        limit: 20, // Load 20 reviews initially
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e, stack) {
      _logger.error('Error loading reviews', e, stack);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final reviews = await _ratingService.getFilteredReviews(
        studentId: widget.studentId,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _error = null;
        });
      }
    } catch (e, stack) {
      _logger.error('Error refreshing reviews', e, stack);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_reviews.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: FadeTransition(
            opacity: _fadeController,
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildReviewCard(_reviews[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/error.json',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadReviews,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 60,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Reviews you\'ve left on food items will appear here',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/stalls'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Find Food to Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final menuName = review['menu']?['food_name'] ?? 'Unknown Menu';
    final stallName =
        review['menu']?['stall']?['nama_stalls'] ?? 'Unknown Stall';
    final rating = (review['rating'] as num).toDouble();
    final comment = review['comment'] ?? '';
    final date = DateTime.parse(review['created_at']).toLocal();

    return GestureDetector(
      // Use the onReviewTap callback if provided
      onTap: () {
        if (widget.onReviewTap != null) {
          widget.onReviewTap!(review);
        } else {
          _showFullReview(review);
        }
      },
      child: Hero(
        tag: 'review_${review['id']}',
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            stallName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, y').format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RatingIndicator(
                  rating: rating,
                  ratingCount: 1,
                  size: 16,
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(comment),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Fix error in image display in review details
  void _showFullReview(Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add proper image handling here
                if (review['menu']?['photo'] != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildSafeImage(
                      review['menu']['photo'], 
                      height: 180,
                    ),
                  ),
                ],
                // Other review details
                _buildFullReviewContent(review),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to handle images safely
  Widget _buildSafeImage(String? imageUrl, {double? height, double? width}) {
    // Validate URL
    if (imageUrl == null || 
        imageUrl.trim().isEmpty || 
        imageUrl.startsWith('file://') || 
        !(imageUrl.startsWith('http://') || 
          imageUrl.startsWith('https://') || 
          imageUrl.startsWith('data:image'))) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        color: Colors.grey[200],
        child: const Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey,
        ),
      );
    }
    
    return Image.network(
      imageUrl,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading image: $error');
        return Container(
          height: height,
          width: width ?? double.infinity,
          color: Colors.grey[200],
          child: const Icon(
            Icons.restaurant,
            size: 48,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildFullReviewContent(Map<String, dynamic> review) {
    final menuName = review['menu']?['food_name'] ?? 'Unknown Menu';
    final stallName =
        review['menu']?['stall']?['nama_stalls'] ?? 'Unknown Stall';
    final rating = (review['rating'] as num).toDouble();
    final comment = review['comment'] ?? '';
    final date = DateTime.parse(review['created_at']).toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          menuName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stallName,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('MMM d, y').format(date),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        RatingIndicator(
          rating: rating,
          ratingCount: 1,
          size: 24,
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(comment),
        ],
      ],
    );
  }
}
