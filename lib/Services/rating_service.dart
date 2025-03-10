import 'package:kantin/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Services/Auth/auth_service.dart';
import 'package:kantin/Services/Database/UserService.dart';

enum ReviewType { menu, stall }

class RatingService {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  final _userService = UserService();
  final Logger _logger = Logger('RatingService');

  // Production-ready cache
  final Map<int, Map<String, dynamic>> _ratingSummaryCache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<int, DateTime> _cacheTimestamps = {};

  // Map to cache rating check results
  final Map<String, bool> _userRatingCache = {};
  final Map<String, DateTime> _ratingCacheTimestamps = {};
  final Duration _ratingCacheDuration = const Duration(minutes: 5);

  Future<int> _getStudentId() async {
    try {
      // Get Firebase user ID
      final firebaseUserId = _authService.currentUserId;
      if (firebaseUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get user data from UserService (which handles Firebase user data)
      final userData = await _userService.getUserByFirebaseUid(firebaseUserId);
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Get student ID from Supabase using the user ID
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('id_user', userData.id!)
          .maybeSingle();

      if (studentData == null) {
        throw Exception('Student profile not found');
      }

      return studentData['id'] as int;
    } catch (e) {
      _logger.error('Failed to get student ID', e);
      throw Exception('Failed to get student ID: $e');
    }
  }

  Future<void> submitReview({
    required int menuId,
    required double rating,
    required int transactionId,
    int? stallId,
    ReviewType type = ReviewType.menu,
    String? comment,
  }) async {
    try {
      _logger.debug('Submitting review for menu_id: $menuId, transaction_id: $transactionId');
      
      // Get student ID 
      final studentId = await _getStudentId();
      
      // Check if a review already exists for this menu and student
      final existingReview = await _supabase
          .from('reviews')
          .select()
          .eq('menu_id', menuId)
          .eq('student_id', studentId)
          .eq('transaction_id', transactionId)
          .maybeSingle();

      if (existingReview != null) {
        throw Exception('You have already reviewed this item');
      }
      
      // If stallId is not provided, get it from menu
      if (stallId == null) {
        final menuData = await _supabase
            .from('menu')
            .select('stall_id')
            .eq('id', menuId)
            .single();
        stallId = menuData['stall_id'] as int;
      }

      // Create the review data with required fields
      // Convert rating to integer since the database column expects an integer
      final Map<String, dynamic> reviewData = {
        'menu_id': menuId,
        'stall_id': stallId,
        'student_id': studentId,
        'transaction_id': transactionId, // Now required per schema
        'rating': rating.round(), // Convert double to integer
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add optional comment if provided
      if (comment != null && comment.isNotEmpty) {
        reviewData['comment'] = comment;
      }

      // Database triggers will automatically update menu and stalls ratings
      await _supabase.from('reviews').insert(reviewData);

      // Clear caches after successful submission
      clearCacheForMenu(menuId);
      clearCacheForStall(stallId);
      clearRatingCheckCache(menuId, transactionId);
      
      _logger.debug('Review submitted successfully');
    } catch (e, stack) {
      if (e is PostgrestException) {
        _handlePostgrestError(e);
      }
      _logger.error('Failed to submit review', e, stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRatingSummary({
    int? menuId,
    int? stallId,
  }) async {
    try {
      if (menuId != null && stallId != null) {
        throw Exception('Provide either menuId or stallId, not both');
      }

      final functionName = menuId != null
          ? 'get_menu_rating_summary'
          : 'get_stall_rating_summary';

      final paramName = menuId != null ? 'menu_id_param' : 'stall_id_param';
      final paramValue = menuId ?? stallId;

      final response = await _supabase.rpc(
        functionName,
        params: {paramName: paramValue},
      );

      return {
        'average_rating':
            (response['average_rating'] as num?)?.toDouble() ?? 0.0,
        'total_reviews': response['total_reviews'] ?? 0,
      };
    } catch (e, stack) {
      _logger.error('Failed to get rating summary', e, stack);
      throw Exception('Failed to get rating summary: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFilteredReviews({
    int? menuId,
    int? stallId,
    int? studentId,
    int? transactionId,
    int? limit = 20, // Add pagination
    int? offset = 0,
  }) async {
    try {
      _logger.debug('Getting filtered reviews for studentId: $studentId');

      // Build query filter with proper type casting
      final Map<String, Object> filter = {
        if (studentId != null) 'student_id': studentId,
        if (menuId != null) 'menu_id': menuId,
        if (stallId != null) 'stall_id': stallId,
        if (transactionId != null) 'transaction_id': transactionId,
      };

      var query = _supabase
          .from('reviews')
          .select('''
        id,
        rating,
        comment,
        created_at,
        student_id,
        menu_id,
        stall_id,
        transaction_id,
        menu:menu_id (
          id,
          food_name,
          price,
          photo,
          stall:stalls (
            id,
            nama_stalls,
            image_url
          )
        )
      ''')
          .match(filter)
          .order('created_at', ascending: false)
          .range(offset ?? 0, (offset ?? 0) + (limit ?? 20) - 1);

      final response = await query;
      _logger.debug('Reviews found: ${response.length}');

      return response;
    } catch (e, stack) {
      _logger.error('Failed to load reviews', e, stack);
      rethrow;
    }
  }

  Future<bool> hasUserRatedMenu(int menuId, int transactionId) async {
    try {
      final cacheKey = 'menu_${menuId}_transaction_$transactionId';

      // Check cache first
      if (_userRatingCache.containsKey(cacheKey)) {
        final cacheTime = _ratingCacheTimestamps[cacheKey];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < _ratingCacheDuration) {
          _logger.debug(
              'Using cached rating check for menu $menuId, transaction $transactionId');
          return _userRatingCache[cacheKey]!;
        }
      }

      _logger.debug(
          'Checking if user has rated menu $menuId for transaction $transactionId');

      final studentId = await _getStudentId();

      final response = await _supabase
          .from('reviews')
          .select()
          .eq('menu_id', menuId)
          .eq('student_id', studentId)
          .eq('transaction_id', transactionId)
          .maybeSingle();

      final hasRated = response != null;

      // Cache the result
      _userRatingCache[cacheKey] = hasRated;
      _ratingCacheTimestamps[cacheKey] = DateTime.now();

      _logger.debug(
          'User has ${hasRated ? '' : 'not '}rated menu $menuId for transaction $transactionId');

      return hasRated;
    } catch (e) {
      _logger.error('Failed to check user rating status', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getMenuRatingSummary(int menuId) async {
    try {
      // Check cache first
      if (_ratingSummaryCache.containsKey(menuId)) {
        final cacheTime = _cacheTimestamps[menuId];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < _cacheDuration) {
          _logger.debug('Using cached rating for menu $menuId');
          return _ratingSummaryCache[menuId]!;
        }
      }

      _logger.debug('Fetching fresh ratings for menu $menuId');
      
      // Get the values directly from the menu table (updated by triggers)
      final menuData = await _supabase
          .from('menu')
          .select('rating, total_ratings')
          .eq('id', menuId)
          .single();
      
      final summary = {
        'average': (menuData['rating'] as num?)?.toDouble() ?? 0.0,
        'count': (menuData['total_ratings'] as num?)?.toInt() ?? 0,
      };

      _cacheRatingSummary(menuId, summary);
      _logger.debug(
          'Fetched ratings for menu $menuId: ${summary['average']} from ${summary['count']} reviews');

      return summary;
    } catch (e, stack) {
      _logger.error(
          'Failed to get menu rating summary for menu $menuId', e, stack);
      return {'average': 0.0, 'count': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getUserReviews(
      {required int studentId}) async {
    try {
      final response = await getFilteredReviews(studentId: studentId);
      return response;
    } catch (e, stack) {
      _logger.error('Failed to get user reviews', e, stack);
      throw Exception('Failed to get user reviews: $e');
    }
  }

  void _cacheRatingSummary(int menuId, Map<String, dynamic> summary) {
    _ratingSummaryCache[menuId] = summary;
    _cacheTimestamps[menuId] = DateTime.now();
  }

  // Add method to clear cache
  void clearCache() {
    _ratingSummaryCache.clear();
    _cacheTimestamps.clear();
  }

  void clearCacheForMenu(int menuId) {
    _ratingSummaryCache.remove(menuId);
    _cacheTimestamps.remove(menuId);
    _logger.debug('Cleared cache for menu $menuId');
  }

  // Add method to clear rating check cache
  void clearRatingCheckCache(int menuId, int transactionId) {
    final cacheKey = 'menu_${menuId}_transaction_$transactionId';
    _userRatingCache.remove(cacheKey);
    _ratingCacheTimestamps.remove(cacheKey);
    _logger.debug(
        'Cleared rating check cache for menu $menuId, transaction $transactionId');
  }

  Future<Map<String, dynamic>> verifyStudent(int studentId) async {
    try {
      final studentData = await _supabase
          .from('students')
          .select()
          .eq('id', studentId)
          .single();

      _logger.debug('Verified student data: $studentData');
      return studentData;
    } catch (e) {
      _logger.error('Failed to verify student', e);
      throw Exception('Failed to verify student: $e');
    }
  }

  void _handlePostgrestError(PostgrestException e) {
    switch (e.code) {
      case '22P02':
        throw Exception('Invalid data type: Rating must be a whole number between 1 and 5');
      case '23503':
        throw Exception(
            'Referenced record not found (transaction, menu, stall, or student)');
      case '23505':
        throw Exception('Review already exists for this transaction');
      case '23514':
        throw Exception('Invalid rating value');
      default:
        _logger.error('Database error', e);
        throw Exception('Failed to submit review: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getStallRatings(int stallId) async {
    try {
      // Check cache
      if (_ratingSummaryCache.containsKey(stallId)) {
        final cacheTime = _cacheTimestamps[stallId];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < _cacheDuration) {
          return _ratingSummaryCache[stallId]!;
        }
      }

      // Get the values directly from the stalls table (updated by triggers)
      final stallData = await _supabase
          .from('stalls')
          .select('rating, total_ratings')
          .eq('id', stallId)
          .single();
      
      final result = {
        'average': (stallData['rating'] as num?)?.toDouble() ?? 0.0,
        'count': (stallData['total_ratings'] as num?)?.toInt() ?? 0,
      };

      _ratingSummaryCache[stallId] = result;
      _cacheTimestamps[stallId] = DateTime.now();

      return result;
    } catch (e) {
      _logger.error('Failed to get stall ratings for stall $stallId', e);
      return {'average': 0.0, 'count': 0};
    }
  }

  // Add method to check if a review is active
  Future<bool> isReviewActive(int reviewId) async {
    try {
      // TODO: Add 'is_active' column to the reviews table for proper review status tracking
      // For now, assume all reviews that exist are active
      final review = await _supabase
          .from('reviews')
          .select('id')
          .eq('id', reviewId)
          .maybeSingle();
      
      return review != null;
    } catch (e) {
      _logger.error('Failed to check review status', e);
      return false;
    }
  }
  
  // Add method to deactivate a review
  Future<void> deactivateReview(int reviewId) async {
    try {
      // TODO: Add 'is_active' column to the reviews table for proper deactivation
      // For now, we'll just delete the review instead of marking it inactive
      await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId);
      
      _logger.debug('Review $reviewId deleted (deactivation not supported yet)');
      
      // The stall and menu ratings will be updated by a database trigger
    } catch (e) {
      _logger.error('Failed to deactivate review', e);
      rethrow;
    }
  }
  
  // Add method to clear cache for a stall
  void clearCacheForStall(int stallId) {
    _ratingSummaryCache.remove(stallId);
    _cacheTimestamps.remove(stallId);
    _logger.debug('Cleared cache for stall $stallId');
  }

  // Debug helper method
  Future<void> debugStallReviews(int stallId) async {
    try {
      final reviews =
          await _supabase.from('reviews').select().eq('stall_id', stallId);

      _logger.debug('''
        Debug info for stall #$stallId:
        Total reviews: ${reviews.length}
        Review details: $reviews
      ''');
    } catch (e) {
      _logger.error('Debug method error', e);
    }
  }
}
