import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kantin/utils/logger.dart';

class RateMenuDialog extends StatefulWidget {
  const RateMenuDialog({
    super.key,
    required this.menuId,
    required this.stallId,
    required this.transactionId,
    required this.menuName,
    required this.onRatingSubmitted,
    this.menuPhoto,
  });

  final int menuId;
  final int stallId;
  final int transactionId;
  final String menuName;
  final String? menuPhoto;
  final Function() onRatingSubmitted;

  @override
  State<RateMenuDialog> createState() => _RateMenuDialogState();
}

class _RateMenuDialogState extends State<RateMenuDialog>
    with SingleTickerProviderStateMixin {
  final _ratingService = RatingService();
  final _commentController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _logger = Logger('RateMenuDialog');
  
  double _rating = 0;
  bool _isSubmitting = false;
  bool _isCheckingExisting = true;
  String _selectedQuickReview = '';
  String _ratingMessage = 'Tap to Rate ⭐';
  String? _errorMessage;
  bool _showSuccess = false;
  
  late final AnimationController _animationController;

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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _checkExistingRating();
  }

  Future<void> _checkExistingRating() async {
    try {
      final hasRating = await _ratingService.hasUserRatedMenu(
        widget.menuId,
        widget.transactionId,
      );

      if (mounted) {
        setState(() {
          _isCheckingExisting = false;
        });
      }

      if (hasRating && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already rated this item'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _logger.error('Error checking existing rating', e);
      if (mounted) {
        setState(() {
          _isCheckingExisting = false;
          _errorMessage = 'Unable to check rating status';
        });
      }
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
                spreadRadius: 1,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _showSuccess 
            ? _buildSuccessView() 
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Image Section
                  _buildHeaderSection(),

                  // Status indicator for initial loading
                  if (_isCheckingExisting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_errorMessage != null)
                    _buildErrorMessage()
                  else ...[
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
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: Colors.green.shade400,
          ).animate().scale(
            begin: Offset(0.5, 0.5),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            'Thank You For Your Review!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ).animate().fade().slideY(begin: 0.3),
          const SizedBox(height: 16),
          Text(
            'Your feedback helps us improve our service',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Close'),
          ).animate().fade(delay: 400.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: widget.menuPhoto != null && widget.menuPhoto!.isNotEmpty
                ? Hero(
                    tag: 'menu_photo_${widget.menuId}',
                    child: CachedNetworkImage(
                      imageUrl: widget.menuPhoto!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => _buildShimmerLoader(),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    ),
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 48,
          alignment: Alignment.center,
          child: Text(
            _ratingMessage,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(_rating),
            ),
            textAlign: TextAlign.center,
            semanticsLabel: 'Rating: $_ratingMessage',
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
          unratedColor: Colors.grey.shade200,
          itemBuilder: (context, index) => Icon(
            Icons.star_rounded,
            color: Colors.amber.shade600,
            semanticLabel: 'Star ${index + 1}',
          ),
          onRatingUpdate: _updateRating,
        ).animate().slideY(begin: 0.3).fadeIn(),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    return switch (rating) {
      5.0 => Colors.green.shade600,
      4.0 => Colors.green.shade600,
      3.0 => Colors.blue.shade600,
      2.0 => Colors.orange.shade600,
      1.0 => Colors.red.shade600,
      _ => Theme.of(context).primaryColor,
    };
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
          elevation: _selectedQuickReview == review ? 2 : 0,
          backgroundColor: _selectedQuickReview == review
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: () => _selectQuickReview(review),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: _selectedQuickReview == review
                ? BorderSide(color: Theme.of(context).primaryColor)
                : BorderSide.none,
          ),
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
            width: 2,
          ),
        ),
        prefixIcon: const Icon(Icons.comment_outlined),
        counterText: '',
      ),
      maxLines: 3,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
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
          backgroundColor: _getRatingColor(_rating),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Submitting...'),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Submit Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded, size: 16),
                ],
              ),
      ),
    );
  }

  void _updateRating(double rating) {
    // Add haptic feedback
    HapticFeedback.selectionClick();
    
    setState(() {
      _rating = rating;
      _ratingMessage = _getRatingMessage(rating);
      _selectedQuickReview = '';
      if (_commentController.text == _selectedQuickReview) {
        _commentController.clear();
      }
    });
    _animationController.forward(from: 0);
  }

  void _selectQuickReview(String review) {
    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_selectedQuickReview == review) {
        _selectedQuickReview = '';
        _commentController.clear();
      } else {
        _selectedQuickReview = review;
        _commentController.text = review;
      }
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
        elevation: 2,
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
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
    );
  }

  Future<void> _submitRating() async {
    if (!mounted) return;
    setState(() => _isSubmitting = true);
    
    try {
      // Double-check for existing rating right before submission
      final hasRating = await _ratingService.hasUserRatedMenu(
        widget.menuId,
        widget.transactionId,
      );
      
      if (hasRating) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already rated this item'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      await _ratingService.submitReview(
        transactionId: widget.transactionId,
        stallId: widget.stallId,
        type: ReviewType.menu,
        rating: _rating,
        menuId: widget.menuId,
        comment: _commentController.text.trim(),
      );
      
      if (!mounted) return;

      // Add haptic feedback on success
      HapticFeedback.mediumImpact();
      
      // Show success animation before closing
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });
      
      // Notify parent
      widget.onRatingSubmitted();
      
      // Close dialog after showing success animation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;
      
      _logger.error('Error submitting rating', e);
      
      setState(() {
        _isSubmitting = false;
        _errorMessage = _getErrorMessage(e);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Failed to submit review'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return switch (error.code) {
        '23505' => 'You have already submitted a review for this item',
        '23514' => 'Invalid rating value (must be between 1-5)',
        '23503' => 'Cannot find the required menu or transaction information',
        _ => 'Database error: ${error.message}',
      };
    }
    
    if (error is String) {
      return error;
    }
    
    return error.toString();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
