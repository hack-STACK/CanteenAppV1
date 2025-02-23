import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class RateMenuDialog extends StatefulWidget {
  const RateMenuDialog({
    super.key,
    required this.menuId,
    required this.stallId,
    required this.transactionId,
    required this.menuName,
    required this.onRatingSubmitted,
    this.menuPhoto, // Make sure we're properly passing this
  });

  final int menuId;
  final int stallId;
  final int transactionId;
  final String menuName;
  final String? menuPhoto; // Add this property declaration
  final Function() onRatingSubmitted;

  @override
  State<RateMenuDialog> createState() => _RateMenuDialogState();
}

class _RateMenuDialogState extends State<RateMenuDialog>
    with SingleTickerProviderStateMixin {
  final _ratingService = RatingService();
  final _commentController = TextEditingController();
  final _supabase = Supabase.instance.client; // Add this line
  double _rating = 0;
  bool _isSubmitting = false;
  String _selectedQuickReview = '';
  late final AnimationController _animationController;
  String _ratingMessage = '';

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
  void initState() {
    super.initState();
    _checkExistingRating();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _checkExistingRating() async {
    try {
      final hasRating = await _ratingService.hasUserRatedMenu(
        widget.menuId,
        widget.transactionId,
      );

      if (hasRating && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already rated this item'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error checking existing rating: $e');
    }
  }

  String _getRatingMessage(double rating) {
    return switch (rating) {
      5.0 => 'Excellent! Thank you! 🌟',
      4.0 => 'Really Good! 😊',
      3.0 => 'It was Okay 👍',
      2.0 => 'Could be Better 😕',
      1.0 => 'Not Good 😢',
      _ => 'Tap to Rate ⭐',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Image Section
              _buildHeaderSection(),

              // Rating Content Section - Scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                      _buildRatingSection(),
                      if (_rating > 0) ...[
                        const SizedBox(height: 24),
                        _buildQuickReviews(),
                        const SizedBox(height: 24),
                        _buildCommentField(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // Submit Button Section - Fixed at bottom
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Update the image section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: widget.menuPhoto != null && widget.menuPhoto!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.menuPhoto!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => _buildShimmerLoader(),
                    errorWidget: (_, __, ___) =>
                        _buildPlaceholder(), // Changed from errorBuilder to errorWidget
                  )
                : _buildPlaceholder(),
          ),
          _buildHeaderOverlay(),
          _buildHeaderContent(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Text(
        widget.menuName,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.2,
          shadows: [Shadow(blurRadius: 8)],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        // Rating Message
        Container(
          height: 48,
          alignment: Alignment.center,
          child: Text(
            _ratingMessage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn().scale(),
        ),
        const SizedBox(height: 16),
        // Rating Stars
        RatingBar.builder(
          initialRating: _rating,
          minRating: 1,
          direction: Axis.horizontal,
          itemCount: 5,
          itemSize: 48,
          glow: true,
          itemBuilder: (context, _) => Icon(
            Icons.star_rounded,
            color: Colors.amber.shade600,
          ),
          onRatingUpdate: _updateRating,
        ).animate().slideY(begin: 0.3).fadeIn(),
      ],
    );
  }

  Widget _buildQuickReviews() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: (_quickReviews[_rating] ?? []).map((review) {
        return ActionChip(
          label: Text(
            review,
            style: TextStyle(
              color: _selectedQuickReview == review
                  ? Colors.white
                  : Colors.black87,
              fontSize: 13,
            ),
          ),
          backgroundColor: _selectedQuickReview == review
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: () => _selectQuickReview(review),
        ).animate().scale(delay: 200.ms);
      }).toList(),
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      decoration: InputDecoration(
        hintText: 'Add your comments (optional)',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
          ),
        ),
        prefixIcon: const Icon(Icons.comment_outlined),
        counterText: '',
      ),
      maxLines: 3,
      maxLength: 200,
    ).animate().slideY(begin: 0.3).fadeIn();
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: FilledButton(
        onPressed: _rating == 0 || _isSubmitting ? null : _submitRating,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _updateRating(double rating) {
    setState(() {
      _rating = rating;
      _ratingMessage = _getRatingMessage(rating);
      _selectedQuickReview = '';
      _commentController.clear();
    });
    _animationController.forward(from: 0);
  }

  void _selectQuickReview(String review) {
    setState(() {
      _selectedQuickReview = review;
      _commentController.text = review;
    });
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No image available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        color: Colors.white.withOpacity(0.9),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => Navigator.of(context).pop(),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.close_rounded,
              size: 24,
              color: Colors.black87,
            ),
          ),
        ),
      ).animate().scale(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
    );
  }

  Future<void> _submitRating() async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await _ratingService.submitReview(
        transactionId: widget.transactionId,
        stallId: widget.stallId,
        type: ReviewType.menu,
        rating: _rating,
        menuId: widget.menuId,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      widget.onRatingSubmitted();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error submitting rating: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
