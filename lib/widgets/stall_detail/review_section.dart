import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class ReviewSection extends StatelessWidget {
  final Stan stall;
  final VoidCallback onSeeAllReviews;

  const ReviewSection({
    super.key,
    required this.stall,
    required this.onSeeAllReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: onSeeAllReviews,
                  child: const Text('See All'),
                ),
              ],
            ),
            // Add review content here
          ],
        ),
      ),
    );
  }
}
