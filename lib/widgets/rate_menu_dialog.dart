import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kantin/Services/rating_service.dart';

class RateMenuDialog extends StatefulWidget {
  final String menuName;
  final int menuId;

  const RateMenuDialog({
    Key? key,
    required this.menuName,
    required this.menuId,
  }) : super(key: key);

  @override
  State<RateMenuDialog> createState() => _RateMenuDialogState();
}

class _RateMenuDialogState extends State<RateMenuDialog> {
  final _ratingService = RatingService();
  final _commentController = TextEditingController();
  double _rating = 0;
  bool _isSubmitting = false;
  String _selectedQuickReview = '';

  // Quick review options based on rating
  final Map<double, List<String>> _quickReviews = {
    5.0: [
      'Perfect! Just amazing 👌',
      'Absolutely delicious! 😋',
      'Best dish ever! ⭐',
      'Outstanding quality',
    ],
    4.0: [
      'Really good! 👍',
      'Enjoyed it very much',
      'Great taste',
      'Would order again',
    ],
    3.0: [
      'It was okay',
      'Could be better',
      'Average taste',
      'Decent portion',
    ],
    2.0: [
      'Below expectations',
      'Not very tasty',
      'Needs improvement',
      'Wouldn\'t recommend',
    ],
    1.0: [
      'Very disappointed',
      'Poor quality',
      'Not good at all',
      'Would not order again',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 400,
          minHeight: 520, // Fixed height to fit all content
          maxHeight: 580, // Increased max height to prevent overflow
        ),
        child: Column(
          children: [
            // Header - Fixed height
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rate Your Order',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView( // Wrap content in SingleChildScrollView
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Menu name
                      Container(
                        height: 40, 
                        alignment: Alignment.center,
                        child: Text(
                          widget.menuName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Rating section with fixed height
                      SizedBox(
                        height: 90,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'How was your experience?',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 16),
                            RatingBar.builder(
                              initialRating: _rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemSize: 40,
                              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                              itemBuilder: (context, _) => Icon(
                                Icons.star_rounded,
                                color: Colors.amber.shade600,
                              ),
                              onRatingUpdate: (rating) {
                                setState(() {
                                  _rating = rating;
                                  _selectedQuickReview = '';
                                  _commentController.text = '';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      // Quick reviews with fixed height
                      if (_rating > 0) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_quickReviews[_rating] ?? [])
                                .take(3)
                                .map((review) => ChoiceChip(
                                      label: Text(
                                        review,
                                        style: TextStyle(
                                          color: _selectedQuickReview == review
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                      selected: _selectedQuickReview == review,
                                      selectedColor: Theme.of(context).primaryColor,
                                      backgroundColor: Colors.grey.shade100,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedQuickReview = review;
                                            _commentController.text = review;
                                          } else {
                                            _selectedQuickReview = '';
                                            _commentController.text = '';
                                          }
                                        });
                                      },
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                      // Comment section with fixed height
                      if (_rating > 0) ...[
                        const SizedBox(height: 40),
                        SizedBox(
                          height: 120,
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add more details to your review (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              counterText: '',
                            ),
                            maxLines: 3,
                            maxLength: 200,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            // Submit button in fixed container at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _rating == 0 || _isSubmitting
                      ? null
                      : () => _submitRating(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Review'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating(BuildContext context) async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      await _ratingService.rateMenuItem(
        widget.menuId,
        _rating,
        _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade100),
                const SizedBox(width: 8),
                const Text('Thank you for your review!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}