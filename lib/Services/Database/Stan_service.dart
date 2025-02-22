import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StanService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Stan> createStan(Stan newStan) async {
    try {
      // Debugging: Print the newStan object before insertion
      print('Inserting Stan: ${newStan.toMap()}');

      // Validate required fields
      if (newStan.stanName.isEmpty || newStan.ownerName.isEmpty) {
        throw Exception('Stan name and owner name are required');
      }

      // Ensure phone number is not null or empty
      if (newStan.phone.isEmpty) {
        throw Exception('Phone number is required');
      }

      // Debugging: Print each field before insertion
      print('Stan Name: ${newStan.stanName}');
      print('Owner Name: ${newStan.ownerName}');
      print('Phone: ${newStan.phone}');
      print('User ID: ${newStan.userId}');
      print('Description: ${newStan.description}');
      print('Slot: ${newStan.slot}');

      // Insert the new stall into the database
      final response = await _client
          .from('stalls')
          .insert({
            'nama_stalls': newStan.stanName,
            'nama_pemilik': newStan.ownerName,
            'no_telp': newStan.phone,
            'id_user': newStan.userId,
            'deskripsi': newStan.description,
            'slot': newStan.slot,
          })
          .select()
          .single();

      // Debugging: Print the response from the database
      print('Response from database: $response');

      return Stan.fromMap(response);
    } catch (e) {
      print('Error creating Stan: $e');
      if (e is PostgrestException) {
        if (e.code == '23505') {
          throw Exception('A stall with this name already exists');
        } else if (e.code == '23503') {
          throw Exception('Invalid user ID provided');
        }
      }
      throw Exception('Failed to create stall: $e');
    }
  }

  Future<List<Stan>> getAllStans() async {
    try {
      final response = await _client.from('stalls').select('''
        *,
        discounts!left(*)
      ''').order('id', ascending: true);

      return (response as List).map((stanMap) {
        try {
          // Handle rating conversion
          if (stanMap['rating'] != null) {
            stanMap['rating'] = stanMap['rating'] is int
                ? (stanMap['rating'] as int).toDouble()
                : (stanMap['rating'] as num).toDouble();
          }

          // Ensure discounts is a list
          if (stanMap['discounts'] == null) {
            stanMap['discounts'] = [];
          }

          return Stan.fromMap(stanMap);
        } catch (e) {
          print('Error parsing stall data: $e');
          // Return a default Stan object or rethrow based on your needs
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error getting all Stans: $e');
      throw Exception('Failed to fetch stalls: $e');
    }
  }

  Future<Stan?> getStanById(int id) async {
    try {
      final response = await _client
          .from('stalls')
          .select()
          .eq('id', id) // Changed from firebase_uid to id
          .single();

      return Stan.fromMap(response);
    } catch (e) {
      print('Error getting Stan by ID: $e');
      if (e is PostgrestException && e.code == 'PGRST116') {
        return null; // Return null if no stall found
      }
      throw Exception('Failed to fetch stall: $e');
    }
  }

  Future<Stan> updateStan(Stan updatedStan) async {
    try {
      // Validate required fields
      if (updatedStan.stanName.isEmpty || updatedStan.ownerName.isEmpty) {
        throw Exception('Stan name and owner name are required');
      }

      final response = await _client
          .from('stalls')
          .update({
            'nama_stalls': updatedStan.stanName,
            'nama_pemilik': updatedStan.ownerName,
            'no_telp': updatedStan.phone,
            'id_user': updatedStan.userId,
            'deskripsi': updatedStan.description,
            'slot': updatedStan.slot,
          })
          .eq('id', updatedStan.id)
          .select()
          .single();

      return Stan.fromMap(response);
    } catch (e) {
      print('Error updating Stan: $e');
      if (e is PostgrestException) {
        if (e.code == '23505') {
          throw Exception('A stall with this name already exists');
        } else if (e.code == '23503') {
          throw Exception('Invalid user ID provided');
        }
      }
      throw Exception('Failed to update stall: $e');
    }
  }

  Future<Stan?> deleteStallsByUserId(int userId) async {
    try {
      final response = await _client
          .from('stalls')
          .delete()
          .eq('id_user', userId)
          .maybeSingle();
      // maybeSingle() returns null if no record was deleted
      if (response == null) return null;
      return Stan.fromMap(response);
    } catch (e) {
      throw Exception('Failed to delete stall for user: $e');
    }
  }

  // New method to check if a stall name exists
  Future<bool> checkStanNameExists(String stanName) async {
    try {
      final response =
          await _client.from('stalls').select('id').eq('nama_stalls', stanName);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking stan name: $e');
      throw Exception('Failed to check stall name: $e');
    }
  }

  Future<Stan> getStallByUserId(int userId) async {
    try {
      print('Fetching stall with ID: $userId');

      // First try to get stall directly by ID
      final stallResponse =
          await _client.from('stalls').select().eq('id', userId).single();

      print('Direct stall response: $stallResponse');
      return Stan.fromMap(stallResponse);
    } catch (e) {
      print('Failed to get stall by ID, trying user_id: $e');

      // If that fails, try by id_user
      try {
        final userStallResponse = await _client
            .from('stalls')
            .select()
            .eq('id_user', userId)
            .single();

        print('User stall response: $userStallResponse');
        return Stan.fromMap(userStallResponse);
      } catch (e2) {
        print('Both queries failed. Final error: $e2');
        throw 'Failed to load stall: No stall found for ID $userId';
      }
    }
  }

  Future<void> updateStoreBanner(int stallId, String bannerUrl) async {
    try {
      await _client
          .from('stan')
          .update({'Banner_img': bannerUrl}).eq('id', stallId);
    } catch (e) {
      print('Error updating store banner: $e');
      throw 'Failed to update store banner';
    }
  }

  Future<void> updateStallStatus(int stallId, bool isOpen) async {
    await _client.from('stalls').update({
      'is_open': isOpen,
    }).eq('id', stallId);
  }

  Future<void> updateOperatingHours(
      int stallId, TimeOfDay openTime, TimeOfDay closeTime) async {
    String timeToString(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    await _client.from('stalls').update({
      'open_time': timeToString(openTime),
      'close_time': timeToString(closeTime),
    }).eq('id', stallId);
  }

  // Add method to auto-update stall status based on time
  Future<void> updateStallStatusBasedOnTime(int stallId) async {
    try {
      final stall = await getStanById(stallId);
      if (stall == null || stall.openTime == null || stall.closeTime == null) {
        return;
      }

      final isCurrentlyOpen = stall.isCurrentlyOpen();
      if (isCurrentlyOpen != stall.isOpen) {
        await updateStallStatus(stallId, isCurrentlyOpen);
      }
    } catch (e) {
      print('Error updating stall status: $e');
      // Handle or rethrow the error as needed
    }
  }
}
