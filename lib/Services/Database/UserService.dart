import 'package:kantin/Models/UsersModels.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabaseClient = Supabase.instance.client;

  Future<UserModel> createUser(UserModel newUser) async {
    try {
      // Validate required fields: make sure email, role, and Firebase UID are provided.
      if (newUser.email.isEmpty ||
          newUser.role.isEmpty ||
          newUser.firebaseUid.isEmpty) {
        throw Exception('Email, role, and Firebase UID are required');
      }

      print(
          'Attempting to create user with Firebase UID: ${newUser.firebaseUid}');

      // Check if the user with the same Firebase UID already exists.
      final firebaseUidExists =
          await checkFirebaseUidExists(newUser.firebaseUid);
      if (firebaseUidExists) {
        throw Exception('User with this Firebase UID already exists');
      }

      // Insert user and get the created user data back.
      // Ensure that newUser.toMap() returns a map where the email is stored under the key "Email"
      final response = await _supabaseClient
          .from('users')
          .insert(newUser.toMap()) // Do not include id in the map
          .select()
          .maybeSingle();

      // Check if the response is null.
      if (response == null) {
        throw Exception('Failed to create user: No response received');
      }

      // Return the created user model.
      return UserModel.fromMap(response);
    } catch (e) {
      print('Error creating user: $e');
      if (e is PostgrestException) {
        if (e.code == '23505') {
          // Unique violation
          throw Exception(
              'Firebase UID already exists. Please use a different UID.');
        }
      }
      throw Exception('Failed to create user: $e');
    }
  }

  Future<bool> checkFirebaseUidExists(String firebaseUid) async {
    try {
      print('Checking for Firebase UID: $firebaseUid');
      final response = await _supabaseClient
          .from('users')
          .select('id')
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();
      print('Response data: $response');
      return response != null;
    } catch (e) {
      print('Error checking Firebase UID: $e');
      throw Exception('Failed to check Firebase UID: $e');
    }
  }

  Future<UserModel?> getUserById(int id) async {
    try {
      final response =
          await _supabaseClient.from('users').select().eq('id', id).single();
      return UserModel.fromMap(response);
    } catch (e) {
      print('Error getting user by ID: $e');
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null; // Return null if no user found.
      }
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<Map<String, dynamic>> updateUserByFirebaseUid(
      String firebaseUid, Map<String, dynamic> data) async {
    final response = await _supabaseClient
        .from('users')
        .update(data)
        .eq('firebase_uid', firebaseUid)
        .select()
        .single();
    return response;
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .order('id', ascending: true);

      return (response as List)
          .map((userMap) => UserModel.fromMap(userMap))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<UserModel> updateUser(UserModel updatedUser) async {
    try {
      // Validate required fields: check email and role.
      if (updatedUser.email.isEmpty || updatedUser.role.isEmpty) {
        throw Exception('Email and role are required');
      }

      final response = await _supabaseClient
          .from('users')
          .update(updatedUser.toMap())
          .eq('id', updatedUser.id ?? 0)
          .select()
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      print('Error updating user: $e');
      if (e is PostgrestException) {
        if (e.code == '23505') {
          throw Exception('Email already exists');
        }
      }
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final result = await _supabaseClient.from('users').delete().eq('id', id);

      if (result == null) {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      // Since the table column is defined as "Email" (case-sensitive), we use that exact name.
      final response =
          await _supabaseClient.from('users').select('id').eq('"Email"', email);
      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      throw Exception('Failed to check email: $e');
    }
  }
}
