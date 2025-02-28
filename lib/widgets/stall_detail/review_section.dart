import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/review_model.dart';
import 'package:shimmer/shimmer.dart';

class ReviewSection extends StatefulWidget {
  final Stan stall;
  final VoidCallback onSeeAllReviews;
  final bool showRating;
  final int maxReviews;
  final int studentId; // Add this property for the current user

  const ReviewSection({
    super.key,
    required this.stall,
    required this.onSeeAllReviews,
    this.showRating = true,
    this.maxReviews = 3,
    required this.studentId, // Make it required
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  // Add debug mode flag
  final bool _debugMode = true; // Set to true to enable debugging UI
  String? _errorMessage;
  late Future<List<StallReview>> _reviewsFuture;
  late Future<Map<String, dynamic>> _ratingSummaryFuture;
  bool _isLoading = true;
  List<StallReview> _reviews = [];
  Map<String, dynamic> _ratingSummary = {
    'average': 0.0,
    'count': 0,
    'distribution': {
      '5': 0,
      '4': 0,
      '3': 0,
      '2': 0,
      '1': 0,
    }
  };

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_debugMode) {
        print('⏳ Loading reviews for stall ID: ${widget.stall.id}');
      }

      // Load reviews and rating summary concurrently
      _reviewsFuture = ReviewService.getStallReviews(widget.stall.id,
          limit: widget.maxReviews);
      _ratingSummaryFuture =
          ReviewService.getStallRatingSummary(widget.stall.id);

      // Wait for both futures to complete
      final results = await Future.wait([_reviewsFuture, _ratingSummaryFuture]);

      _reviews = results[0] as List<StallReview>;
      _ratingSummary = results[1] as Map<String, dynamic>;

      if (_debugMode) {
        print('✅ Loaded ${_reviews.length} reviews');
        print('📊 Rating summary: $_ratingSummary');

        // Print each review for debugging
        if (_reviews.isNotEmpty) {
          print('\n--- Review Details ---');
          for (var review in _reviews) {
            print('ID: ${review.id}');
            print('User: ${review.userName}');
            print('Rating: ${review.rating}');
            print('Menu: ${review.menuName ?? 'N/A'}');
            print('Comment: ${review.comment ?? 'No comment'}');
            print('-------------------------\n');
          }
        } else {
          print('⚠️ No reviews found!');
        }
      }
    } catch (e, stackTrace) {
      _errorMessage = 'Error: $e';
      print('❌ Error loading reviews: $e');
      print('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _getAverageRating() {
    return _ratingSummary['average'] ?? 0.0;
  }

  int _getTotalRatings() {
    return _ratingSummary['count'] ?? 0;
  }

  double _getRatingPercentage(int rating) {
    final totalRatings = _getTotalRatings();
    if (totalRatings == 0) return 0;

    final count = _ratingSummary['distribution']?['$rating'] ?? 0;
    return count / totalRatings;
  }

  // Add method to handle write review action
  void _handleWriteReview() {
    showDialog(
      context: context,
      builder: (context) => _buildReviewDialog(),
    );
  }

  // Create review submission dialog
  Widget _buildReviewDialog() {
    final ratingController = ValueNotifier<double>(3.0);
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Write a Review'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Rate your experience',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<double>(
                        valueListenable: ratingController,
                        builder: (context, value, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => GestureDetector(
                                onTap: () {
                                  ratingController.value = index + 1.0;
                                },
                                child: Icon(
                                  index < value
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 36,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Your Review'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your experience with this stall...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your review';
                    }
                    return null;
                  },
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        setState(() {
                          isSubmitting = true;
                        });

                        // Submit review using the ReviewService
                        final success = await ReviewService.submitReview(
                          studentId: widget.studentId,
                          stallId: widget.stall.id,
                          transactionId:
                              0, // Use 0 for direct reviews (adjust as needed)
                          rating: ratingController.value.toInt(),
                          comment: commentController.text.trim(),
                        );

                        if (success) {
                          Navigator.pop(context);
                          _showSuccessSnackBar();
                          _loadReviews(); // Refresh reviews after submission
                        } else {
                          _showErrorSnackBar('Failed to submit review');
                        }
                      } catch (e) {
                        print('Error submitting review: $e');
                        _showErrorSnackBar('Error: $e');
                      } finally {
                        if (mounted) {
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      }
                    }
                  },
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Your review was submitted successfully'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          // Only show rating summary if there are actual ratings AND showRating is true
          if (_getTotalRatings() > 0 && widget.showRating)
            _buildRatingSummary(),
          // Add debug section
          if (_debugMode && _errorMessage != null) _buildErrorMessage(),
          _buildReviewsList(),
          _buildFooter(),
        ],
      ),
    );
  }

  // Add the missing _buildErrorMessage method
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error Loading Reviews',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'Unknown error occurred',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.red.shade700),
            onPressed: _loadReviews,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Customer Reviews',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          // Only show rating badge if there are actual ratings
          if (_getTotalRatings() > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _getAverageRating().toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    ' (${_getTotalRatings()})',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big rating number
          Text(
            _getAverageRating().toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          // Rating bars
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5, _getRatingPercentage(5)),
                const SizedBox(height: 4),
                _buildRatingBar(4, _getRatingPercentage(4)),
                const SizedBox(height: 4),
                _buildRatingBar(3, _getRatingPercentage(3)),
                const SizedBox(height: 4),
                _buildRatingBar(2, _getRatingPercentage(2)),
                const SizedBox(height: 4),
                _buildRatingBar(1, _getRatingPercentage(1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, double percentage) {
    return Row(
      children: [
        Text(
          '$rating',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                rating >= 4
                    ? Colors.green
                    : rating >= 3
                        ? Colors.amber
                        : Colors.red,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_reviews.isEmpty) {
      return _buildNoReviews();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewItem(review);
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity * 0.7,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoReviews() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getTotalRatings() > 0
                  ? 'No Reviews to Display'
                  : 'No Reviews Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getTotalRatings() > 0
                  ? 'There are ratings but no review comments yet'
                  : 'Be the first to share your experience\nwith this stall',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            // Debug data section
            if (_debugMode) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stall ID: ${widget.stall.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Rating Count: ${_getTotalRatings()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Reviews Loaded: ${_reviews.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadReviews,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Force Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.all(8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleWriteReview, // Connect to the handler
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Write a Review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(StallReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            _buildUserAvatar(review),
            const SizedBox(width: 12),
            // User info and rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Star rating
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating.floor()
                              ? Icons.star
                              : index < review.rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Date
                      Text(
                        review.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Food item tag - show which food the review is for
        if (review.menuName != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fastfood,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  review.menuName!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Review comment - Improved to handle null comments properly
        if (review.comment != null && review.comment!.isNotEmpty)
          Text(
            review.comment!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          )
        else
          Text(
            review.menuName != null
                ? 'This user left a rating for ${review.menuName} without a comment.'
                : 'This user left a rating without a comment.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),

        const SizedBox(height: 12),
        // Review actions
        Row(
          children: [
            // Like button
            InkWell(
              onTap: () {
                // Handle like action
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      review.hasUserLiked ?? false
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      size: 16,
                      color: review.hasUserLiked ?? false
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.likes?.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 14,
                        color: review.hasUserLiked ?? false
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Reply button
            InkWell(
              onTap: () {
                // Handle reply action
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserAvatar(StallReview review) {
    if (review.userAvatar != null && review.userAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(review.userAvatar!),
        backgroundColor: Colors.grey[200],
      );
    }

    // Generate a color based on the user ID
    final int colorSeed = review.studentId.hashCode;
    final List<Color> avatarColors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
      Colors.red.shade300,
    ];
    final Color avatarColor = avatarColors[colorSeed % avatarColors.length];

    return CircleAvatar(
      radius: 20,
      backgroundColor: avatarColor,
      child: Text(
        review.userInitials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: _handleWriteReview, // Connect to the handler method
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Write Review'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onSeeAllReviews,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text('See All (${_getTotalRatings()})'),
          ),
        ],
      ),
    );
  }
}
