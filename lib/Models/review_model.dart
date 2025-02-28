import 'package:supabase_flutter/supabase_flutter.dart';

class StallReview {
  final int id;
  final int studentId;
  final int stallId;
  final int? menuId;
  final String? menuName; // Added field to store the food item name
  final int transactionId;
  final String userName; // We'll join with students table
  final String? userAvatar; // We'll join with students table
  final int rating;
  final String? comment;
  final DateTime reviewDate;
  final List<String>? images;
  final int? likes;
  final bool? hasUserLiked;
  final Map<String, int>? ratingBreakdown;

  StallReview({
    required this.id,
    required this.studentId,
    required this.stallId,
    this.menuId,
    this.menuName, // Added parameter
    required this.transactionId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    required this.reviewDate,
    this.images,
    this.likes = 0,
    this.hasUserLiked = false,
    this.ratingBreakdown,
  });

  factory StallReview.fromMap(Map<String, dynamic> map) {
    return StallReview(
      id: map['id'],
      studentId: map['student_id'],
      stallId: map['stall_id'],
      menuId: map['menu_id'],
      menuName: map['menu_name'], // Added to retrieve menu name
      transactionId: map['transaction_id'],
      userName:
          map['student_name'] ?? 'Anonymous User', // From joined student table
      userAvatar: map['student_avatar'], // From joined student table
      rating: map['rating'],
      comment: map['comment'],
      reviewDate: DateTime.parse(map['created_at']),
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      likes: map['likes'] ?? 0,
      hasUserLiked: map['has_user_liked'] ?? false,
    );
  }

  // Helper methods for display
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(reviewDate);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Just now';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  // Get user initials for avatar placeholder
  String get userInitials {
    if (userName.isEmpty) return '';

    final nameParts = userName.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  // Add method to check if the review belongs to the current user
  bool isFromCurrentUser(int currentStudentId) {
    return studentId == currentStudentId;
  }

  // Add method to get display name based on whether review is from current user
  String getDisplayName(int currentStudentId) {
    return isFromCurrentUser(currentStudentId) ? 'Me' : userName;
  }
}

class ReviewService {
  static final _supabase = Supabase.instance.client;
  static final bool _debugMode = true; // Enable debug mode

  static Future<List<StallReview>> getStallReviews(int stallId,
      {int limit = 5, int? studentId}) async {
    try {
      if (_debugMode) {
        print('🔍 Fetching reviews for stall ID: $stallId with limit: $limit');
      }

      // FIXED: Changed !inner join to left join (remove the ! character)
      // This allows reviews to be returned even if student data is missing
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            students(
              id,
              nama_siswa,
              foto
            ),
            menu(
              id,
              food_name
            )
          ''')
          .eq('stall_id', stallId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (_debugMode) {
        print('📦 Raw response data: $response');
      }

      if ((response as List).isEmpty) {
        if (_debugMode) print('⚠️ No reviews found for stall $stallId');
        return [];
      }

      final List<StallReview> reviews = [];
      for (var item in response) {
        try {
          final studentData = item['students'];
          final menuData = item['menu'];

          if (_debugMode) {
            print('\n--- Processing Review ---');
            print('Review ID: ${item['id']}');
            print('Student data: $studentData');
            print('Menu data: $menuData');
            print('Comment: ${item['comment']}');
          }

          // FIXED: Updated field names to match the actual database column names
          // Handle null student data - don't crash, use default values
          final studentName =
              studentData != null && studentData['nama_siswa'] != null
                  ? studentData['nama_siswa']
                  : 'Anonymous User';
          final studentAvatar =
              studentData != null ? studentData['foto'] : null;

          // Handle null menu data
          final menuName = menuData != null ? menuData['food_name'] : null;

          final review = StallReview(
            id: item['id'],
            studentId: item['student_id'],
            stallId: item['stall_id'],
            menuId: item['menu_id'],
            menuName: menuName,
            transactionId: item['transaction_id'],
            userName: studentName,
            userAvatar: studentAvatar,
            rating: item['rating'],
            comment: item['comment'],
            reviewDate: DateTime.parse(item['created_at']),
            likes: item['likes'],
            hasUserLiked: item['has_user_liked'],
          );

          reviews.add(review);

          if (_debugMode) {
            print('✅ Successfully processed review ${review.id}');
            print('User Name: ${review.userName}'); // Debug the username
            print('------------------------\n');
          }
        } catch (e, stackTrace) {
          print('❌ Error parsing review data: $e');
          print('Data that caused error: $item');
          print('Stack trace: $stackTrace');
        }
      }

      if (_debugMode) {
        print('📊 Total reviews parsed: ${reviews.length}');
      }

      return reviews;
    } catch (e, stackTrace) {
      print('❌ Error fetching stall reviews: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Rethrow to let the UI handle it
    }
  }

  static Future<Map<String, dynamic>> getStallRatingSummary(int stallId) async {
    try {
      // Get all ratings for this stall
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('stall_id', stallId);

      if ((response as List).isEmpty) {
        return {
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
      }

      final ratings =
          (response as List).map((item) => item['rating'] as int).toList();

      // Calculate average
      final sum = ratings.fold<int>(0, (sum, rating) => sum + rating);
      final average = ratings.isEmpty ? 0.0 : sum / ratings.length;

      // Calculate distribution
      final distribution = {
        '5': ratings.where((r) => r == 5).length,
        '4': ratings.where((r) => r == 4).length,
        '3': ratings.where((r) => r == 3).length,
        '2': ratings.where((r) => r == 2).length,
        '1': ratings.where((r) => r == 1).length,
      };

      return {
        'average': average,
        'count': ratings.length,
        'distribution': distribution,
      };
    } catch (e) {
      print('Error fetching stall rating summary: $e');
      return {
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
    }
  }

  static Future<Map<int, int>> getItemPopularity(int stallId,
      {int limit = 10}) async {
    try {
      // Query transaction_items to get the popularity of menu items
      final response = await _supabase.rpc('get_menu_popularity',
          params: {'stall_id_param': stallId, 'limit_param': limit});

      if (response == null) {
        return {};
      }

      // Convert to map of menu_id: order_count
      final Map<int, int> popularity = {};
      for (var item in response) {
        try {
          popularity[item['menu_id']] = item['order_count'];
        } catch (e) {
          print('Error parsing item popularity: $e');
        }
      }

      return popularity;
    } catch (e) {
      print('Error fetching item popularity: $e');
      return {};
    }
  }

  static Future<bool> submitReview({
    required int studentId,
    required int stallId,
    required int transactionId,
    int? menuId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _supabase.from('reviews').insert({
        'student_id': studentId,
        'stall_id': stallId,
        'transaction_id': transactionId,
        'menu_id': menuId,
        'rating': rating,
        'comment': comment,
      });

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }
}
