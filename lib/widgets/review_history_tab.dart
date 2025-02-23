import 'package:flutter/material.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:intl/intl.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/widgets/rating_indicator.dart';

class ReviewHistoryTab extends StatefulWidget {
  final int studentId;

  const ReviewHistoryTab({super.key, required this.studentId});

  @override
  State<ReviewHistoryTab> createState() => _ReviewHistoryTabState();
}

class _ReviewHistoryTabState extends State<ReviewHistoryTab> {
  final RatingService _ratingService = RatingService();
  final Logger _logger = Logger('ReviewHistoryTab'); // Add this line
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
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
        limit: 10, // Load 10 reviews initially
      );

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          final menuName = review['menu']?['food_name'] ?? 'Unknown Menu';
          final stallName =
              review['menu']?['stall']?['nama_stalls'] ?? 'Unknown Stall';
          final rating = (review['rating'] as num).toDouble();
          final comment = review['comment'] ?? '';
          final date = DateTime.parse(review['created_at']).toLocal();

          return GestureDetector(
            onTap: () => _showFullReview(review),
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
        },
      ),
    );
  }

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
                // Review details
                _buildFullReviewContent(review),
              ],
            ),
          ),
        ),
      ),
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
