// import 'dart:typed_data';
// import 'package:kantin/Models/Stan_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:kantin/Models/Stall_model.dart';

// class StallService {
//   final SupabaseClient _client = Supabase.instance.client;

//   Future<int?> getCorrectUserId(int currentUserId) async {
//     try {
//       // First check if this user has any stalls
//       final stalls = await _client
//           .from('stalls')
//           .select('id_user')
//           .eq('id_user', currentUserId)
//           .maybeSingle();

//       if (stalls != null) {
//         print('Found stall with current user ID: $currentUserId');
//         return currentUserId;
//       }

//       // If no stalls found, check if this is a stall ID instead of user ID
//       final stallDetails = await _client
//           .from('stalls')
//           .select('id_user')
//           .eq('id', currentUserId)
//           .maybeSingle();

//       if (stallDetails != null) {
//         final correctUserId = stallDetails['id_user'] as int;
//         print(
//             'Found correct user ID: $correctUserId for stall ID: $currentUserId');
//         return correctUserId;
//       }

//       print('No stall or user ID found for ID: $currentUserId');
//       return null;
//     } catch (e) {
//       print('Error in getCorrectUserId: $e');
//       return null;
//     }
//   }

//   Future<List<Stan>> getStallsByUserId(int userId) async {
//     try {
//       print('Starting database query for user ID: $userId');

//       // Get the correct user ID first
//       final correctUserId = await getCorrectUserId(userId);
//       if (correctUserId == null) {
//         print('Could not determine correct user ID');
//         return [];
//       }

//       final response =
//           await _client.from('stalls').select().eq('id_user', correctUserId);

//       print('Raw database response: $response');

//       if ((response as List).isEmpty) {
//         print('No stalls found for user ID: $correctUserId');
//         return [];
//       }

//       final stalls =
//           (response as List).map((json) => Stan.fromMap(json)).toList();
//       print('Successfully parsed ${stalls.length} stalls');
//       return stalls;
//     } catch (e) {
//       print('Error fetching stalls: $e');
//       rethrow;
//     }
//   }

//   Future<Stan> createStall(Stan stall) async {
//     try {
//       final response =
//           await _client.from('stalls').insert(stall.toMap()).select().single();

//       return Stan.fromMap(response);
//     } catch (e) {
//       print('Error creating stall: $e');
//       rethrow;
//     }
//   }

//   Future<Stan> updateStall(Stan stall) async {
//     try {
//       final response = await _client
//           .from('stalls')
//           .update(stall.toMap())
//           .eq('id', stall.id)
//           .select()
//           .single();

//       return Stan.fromMap(response);
//     } catch (e) {
//       print('Error updating stall: $e');
//       rethrow;
//     }
//   }

//   Future<String?> uploadStallImage(
//       int stallId, List<int> fileBytes, String fileName) async {
//     try {
//       final String path = 'stall-images/stall_${stallId}_$fileName';
//       await _client.storage
//           .from('stalls')
//           .uploadBinary(path, Uint8List.fromList(fileBytes));

//       final String imageUrl = _client.storage.from('stalls').getPublicUrl(path);

//       // Update the stall with the new image URL
//       await _client
//           .from('stalls')
//           .update({'image_url': imageUrl}).eq('id', stallId);

//       return imageUrl;
//     } catch (e) {
//       print('Error uploading stall image: $e');
//       rethrow;
//     }
//   }

//   Future<void> deleteStall(int id) async {
//     try {
//       // First, delete related storage items if any
//       try {
//         await _client.storage
//             .from('stalls')
//             .remove(['stall-images/stall_${id}_*']);
//       } catch (e) {
//         print('Warning: Could not delete stall images: $e');
//       }

//       // Then delete the stall record
//       await _client.from('stalls').delete().eq('id', id);
//     } catch (e) {
//       throw 'Failed to delete stall: ${e.toString()}';
//     }
//   }

//   Future<Stan> getStallByUserId(int userId) async {
//     try {
//       print('Fetching stall with ID: $userId');

//       // First try to get stall directly by ID
//       final stallResponse =
//           await _client.from('stalls').select().eq('id', userId).single();

//       print('Direct stall response: $stallResponse');
//       return Stan.fromMap(stallResponse);
//     } catch (e) {
//       print('Failed to get stall by ID, trying user_id: $e');

//       // If that fails, try by id_user
//       try {
//         final userStallResponse = await _client
//             .from('stalls')
//             .select()
//             .eq('id_user', userId)
//             .single();

//         print('User stall response: $userStallResponse');
//         return Stan.fromMap(userStallResponse);
//       } catch (e2) {
//         print('Both queries failed. Final error: $e2');
//         throw 'Failed to load stall: No stall found for ID $userId';
//       }
//     }
//   }
// }
