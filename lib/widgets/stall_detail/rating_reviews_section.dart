import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class RatingReviewsSection extends StatelessWidget {
  final Stan stall;
  final VoidCallback onSeeAllReviews;

  const RatingReviewsSection({
    super.key,
    required this.stall,
    required this.onSeeAllReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ratings & Reviews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: onSeeAllReviews,
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRatingOverview(),
                const SizedBox(width: 24),
                Expanded(child: _buildRatingBars()),
              ],
            ),
            const Divider(height: 32),
            _buildRecentReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Column(
      children: [
        Text(
          stall.rating?.toStringAsFixed(1) ?? 'N/A',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${stall.reviewCount} reviews',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBars() {
    // TODO: Implement actual rating distribution
    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index;
        final percentage = 0.2; // Mock data
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$rating',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRecentReviews() {
    // TODO: Implement actual reviews
    return const Center(
      child: Text('No reviews yet'),
    );
  }
}
