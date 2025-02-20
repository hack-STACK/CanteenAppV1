import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Services/Auth/auth_service.dart';

class RatingService {
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  Future<void> rateMenuItem(int menuId, double rating, String comment) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Validate rating range according to schema constraints
      if (rating < 1.0 || rating > 5.0) {
        throw Exception('Rating must be between 1 and 5');
      }

      await _supabase.from('menu_ratings').upsert({
        'menu_id': menuId,
        'user_id': userId,
        'rating': rating,
        'comment': comment.isEmpty ? null : comment,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'menu_id,user_id'); // Fixed: Pass as parameter to upsert
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        // Foreign key violation
        throw Exception('Menu not found');
      } else if (e.code == '23514') {
        // Check constraint violation
        throw Exception('Invalid rating value');
      }
      throw Exception('Failed to submit rating: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  Future<bool> hasUserRatedMenu(int menuId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) return false;

      final response = await _supabase
          .from('menu_ratings')
          .select('id') // Only select id for efficiency
          .eq('menu_id', menuId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking user rating: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getMenuRatingSummary(int menuId) async {
    try {
      final response = await _supabase.rpc('get_menu_rating_summary',
          params: {'menu_id_param': menuId}).select();

      if (response.isEmpty) {
        return {
          'average': 0.0,
          'count': 0,
        };
      }

      final result = response.first;
      return {
        'average': (result['average'] as num?)?.toDouble() ?? 0.0,
        'count': (result['count'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('Error getting menu rating summary: $e');
      return {
        'average': 0.0,
        'count': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getUserReviews() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.from('menu_ratings').select('''
            id,
            menu_id,
            rating,
            comment,
            created_at,
            menu:menu!menu_id (
              id,
              food_name
            )
          ''').eq('user_id', userId).order('created_at', ascending: false);

      return (response as List).map((item) {
        final menu = item['menu'] as Map<String, dynamic>;
        return {
          'id': item['id'],
          'menu_id': item['menu_id'],
          'rating': (item['rating'] as num).toDouble(),
          'comment': item['comment'],
          'created_at': item['created_at'],
          'menu_name':
              menu['food_name'], // Changed to match your menu table column name
        };
      }).toList();
    } catch (e) {
      print('Error in getUserReviews: $e'); // Add debug print
      throw Exception('Failed to load reviews: $e');
    }
  }

  // Optional: Add method to delete a rating
  Future<void> deleteRating(int ratingId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('menu_ratings').delete().match(
          {'id': ratingId, 'user_id': userId}); // Ensure user owns the rating
    } catch (e) {
      throw Exception('Failed to delete rating: $e');
    }
  }
}
