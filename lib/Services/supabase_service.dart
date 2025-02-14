import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  static SupabaseClient get client => _client;

  // Helper method to check connection
  static Future<bool> checkConnection() async {
    try {
      await _client.from('health_check').select().limit(1);
      return true;
    } catch (e) {
      print('Supabase connection error: $e');
      return false;
    }
  }

  // Helper method for error handling
  static String handleError(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    } else if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }
}