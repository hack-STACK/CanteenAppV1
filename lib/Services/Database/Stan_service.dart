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
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    }

    try {
      print('Starting schedule update operation for stall ID: $stallId');
      final openTimeStr = timeToString(openTime);
      final closeTimeStr = timeToString(closeTime);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      // CRITICAL FIX: First get all existing schedules to check if we need to update or insert
      final existingSchedules = await _client
          .from('stall_schedules')
          .select('id, day_of_week')
          .eq('stall_id', stallId)
          .filter('specific_date', 'is', Null); // Use is_ for null check

      // Create a map for quick lookups
      Map<String, int> existingScheduleMap = {};
      for (var schedule in existingSchedules) {
        existingScheduleMap[schedule['day_of_week']] = schedule['id'];
      }

      print('Found ${existingScheduleMap.length} existing schedules');

      // Process each day separately - UPDATE if exists, INSERT only if doesn't exist
      for (String day in weekdays) {
        if (existingScheduleMap.containsKey(day)) {
          // UPDATE existing record
          int scheduleId = existingScheduleMap[day]!;
          print('UPDATING existing schedule for $day with ID: $scheduleId');

          await _client.from('stall_schedules').update({
            'open_time': openTimeStr,
            'close_time': closeTimeStr,
            'is_open': true,
          }).eq('id', scheduleId);
        } else {
          // Only INSERT if no record exists for this day
          print('Creating new schedule for $day (not found in database)');
          await _client.from('stall_schedules').insert({
            'stall_id': stallId,
            'day_of_week': day,
            'open_time': openTimeStr,
            'close_time': closeTimeStr,
            'is_open': true,
            'specific_date': null
          });
        }
      }

      print(
          'Successfully updated all schedules with explicit UPDATE/INSERT separation');
    } catch (e) {
      print('Error updating operating hours: $e');
      throw Exception('Failed to update operating hours: $e');
    }
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

  // Replace the updateManualOpenStatus method to use the stalls table instead
  Future<void> updateManualOpenStatus(int stallId, bool isManuallyOpen) async {
    try {
      print(
          'Updating manual open status in stall_schedules table for stall ID: $stallId');

      // First check if we have a special "manual override" record
      final existingOverride = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', 'override') // Using 'override' as a special value
          .maybeSingle();

      if (existingOverride != null) {
        // Update existing override record - removed notes field
        await _client.from('stall_schedules').update({
          'is_open': isManuallyOpen, // Store manual status in is_open field
        }).eq('id', existingOverride['id']);

        print('Updated existing manual override record');
      } else {
        // Create new override record - removed notes field
        await _client.from('stall_schedules').insert({
          'stall_id': stallId,
          'day_of_week':
              'override', // Special value to indicate this is not a regular schedule
          'is_open': isManuallyOpen,
          'open_time': '00:00:00', // Default values
          'close_time': '23:59:59',
          'specific_date': null
        });

        print('Created new manual override record');
      }
    } catch (e) {
      print('Error updating manual open status: $e');
      throw Exception('Failed to update manual override setting: $e');
    }
  }

  // Update the getCompleteScheduleInfo method to get manual override from stalls table
  Future<Map<String, dynamic>> getCompleteScheduleInfo(int stallId) async {
    try {
      // Get regular schedules
      final schedules = await getStallSchedules(stallId);

      // Get manual override record
      final manualOverride = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', 'override')
          .maybeSingle();

      // Get stall info for current open status
      final stallInfo = await _client
          .from('stalls')
          .select('is_open')
          .eq('id', stallId)
          .single();

      bool isManuallyOpen = manualOverride != null ? true : false;
      bool manualStatus =
          manualOverride != null ? (manualOverride['is_open'] ?? false) : false;

      return {
        'regularSchedules': schedules,
        'manualOverride': {
          'isManuallyOpen': isManuallyOpen,
          'isOpen': stallInfo['is_open'] ?? true,
          'manualStatus': manualStatus
        }
      };
    } catch (e) {
      print('Error getting complete schedule info: $e');
      throw Exception('Failed to fetch schedule information: $e');
    }
  }

  // Update checkIfStoreIsOpenNow to use the stalls table for manual overrides
  Future<bool> checkIfStoreIsOpenNow(int stallId) async {
    try {
      // Check for manual override first
      final manualOverride = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', 'override')
          .maybeSingle();

      // If manual override exists and is active, use its status
      if (manualOverride != null) {
        return manualOverride['is_open'] ?? false;
      }

      // Otherwise, check the schedule for the current day
      final now = DateTime.now();
      final currentDay = _getDayOfWeek(now.weekday);
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final schedule = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', currentDay)
          .filter('specific_date', 'is', null)
          .maybeSingle();

      if (schedule == null) {
        return false; // No schedule found for today
      }

      if (!(schedule['is_open'] ?? false)) {
        return false; // Store is closed for this day
      }

      final openTime = schedule['open_time'] ?? '00:00:00';
      final closeTime = schedule['close_time'] ?? '23:59:59';

      // Check if current time is within operating hours
      return currentTime.compareTo(openTime) >= 0 &&
          currentTime.compareTo(closeTime) <= 0;
    } catch (e) {
      print('Error checking store open status: $e');
      return false; // Default to closed on error
    }
  }

  // Get all schedules for a stall
  Future<List<Map<String, dynamic>>> getStallSchedules(int stallId) async {
    try {
      final response = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .filter('specific_date', 'is', null);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting stall schedules: $e');
      throw Exception('Failed to fetch stall schedules: $e');
    }
  }

  // Update schedules for all days of the week
  Future<void> updateStallSchedules(
      int stallId, List<Map<String, dynamic>> schedules) async {
    try {
      print('Starting multiple schedule update for stall ID: $stallId');

      // Get existing schedules to determine update vs insert
      final existingSchedules = await getStallSchedules(stallId);

      // Create a map for quick lookups
      Map<String, int> existingScheduleMap = {};
      for (var schedule in existingSchedules) {
        if (schedule['day_of_week'] != null) {
          existingScheduleMap[schedule['day_of_week']] = schedule['id'];
        }
      }

      // Track operations for easier debugging
      int updatedCount = 0;
      int insertedCount = 0;

      // Process each day's schedule
      for (final schedule in schedules) {
        final String day = schedule['day_of_week'];

        if (existingScheduleMap.containsKey(day)) {
          // UPDATE existing record
          int scheduleId = existingScheduleMap[day]!;
          await _client.from('stall_schedules').update({
            'open_time': schedule['open_time'],
            'close_time': schedule['close_time'],
            'is_open': schedule['is_open'],
          }).eq('id', scheduleId);
          updatedCount++;
        } else {
          // INSERT new record
          await _client.from('stall_schedules').insert({
            'stall_id': stallId,
            'day_of_week': day,
            'open_time': schedule['open_time'],
            'close_time': schedule['close_time'],
            'is_open': schedule['is_open'],
            'specific_date': null
          });
          insertedCount++;
        }
      }

      print(
          'Schedule update completed: Updated $updatedCount records, inserted $insertedCount records');
    } catch (e) {
      print('Error updating stall schedules: $e');
      throw Exception('Failed to update stall schedules: $e');
    }
  }

  // Update store status based on current schedule
  Future<void> updateStoreStatusBasedOnSchedule(int stallId) async {
    try {
      // Get stall info to check if manual override is enabled
      final stallInfo = await _client
          .from('stalls')
          .select('is_manually_open, is_open')
          .eq('id', stallId)
          .single();

      final bool isManuallyOpen = stallInfo['is_manually_open'] ?? false;

      // If manual override is enabled, don't change the status
      if (isManuallyOpen) {
        print('Manual override is active, skipping automatic status update');
        return;
      }

      // Otherwise, check the schedule for the current day
      final now = DateTime.now();
      final currentDay = _getDayOfWeek(now.weekday);
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      // Try to get the schedule for today
      final scheduleResponse = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', currentDay)
          .maybeSingle();

      // Check if we have a schedule and if the store should be open
      if (scheduleResponse != null) {
        final bool isDayOpen = scheduleResponse['is_open'] ?? false;

        if (!isDayOpen) {
          // Store is closed for the day
          await updateStallStatus(stallId, false);
          return;
        }

        final String openTime = scheduleResponse['open_time'] ?? '00:00:00';
        final String closeTime = scheduleResponse['close_time'] ?? '23:59:59';

        // Check if current time is within operating hours
        final bool isWithinHours = currentTime.compareTo(openTime) >= 0 &&
            currentTime.compareTo(closeTime) <= 0;

        // Update the stall status
        await updateStallStatus(stallId, isWithinHours);
      }
    } catch (e) {
      print('Error updating store status based on schedule: $e');
      // Log but don't throw - this shouldn't break the app
    }
  }

  // Helper method to convert weekday number to day string
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Mon';
    }
  }

  // Add these methods to the StanService class

  // Get schedules for all days of the week for a specific stall
  Future<Map<String, dynamic>> getStallSchedulesByDay(int stallId) async {
    try {
      // Retrieve all schedule records for this stall
      final response = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .filter('specific_date', 'is',
              null); // Only get regular schedules, not date-specific ones

      // Create a map with day_of_week as key for easier access
      Map<String, dynamic> scheduleByDay = {};

      // Initialize with default values for all days
      for (String day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        scheduleByDay[day] = {
          'is_open': false,
          'open_time': '09:00:00',
          'close_time': '17:00:00',
        };
      }

      // Update with actual values from database
      for (final record in response) {
        final String day = record['day_of_week'];
        if (day != null && scheduleByDay.containsKey(day)) {
          scheduleByDay[day] = {
            'id': record['id'],
            'is_open': record['is_open'] ?? false,
            'open_time': record['open_time'] ?? '09:00:00',
            'close_time': record['close_time'] ?? '17:00:00',
          };
        }
      }

      return scheduleByDay;
    } catch (e) {
      print('Error getting stall schedules: $e');
      throw Exception('Failed to fetch schedules: $e');
    }
  }

  // Update the updateDaySchedule method to only create or update when needed
  Future<void> updateDaySchedule(
      int stallId, String dayOfWeek, Map<String, dynamic> scheduleData) async {
    try {
      // Only proceed if the day is actually marked as open
      // This helps avoid creating unnecessary closed day entries
      bool isOpen = scheduleData['is_open'] ?? false;

      // Check if this record already exists (either by ID or by querying)
      int? existingId;
      if (scheduleData.containsKey('id')) {
        existingId = scheduleData['id'];
      } else {
        final existing = await _client
            .from('stall_schedules')
            .select('id')
            .eq('stall_id', stallId)
            .eq('day_of_week', dayOfWeek)
            .filter('specific_date', 'is', null)
            .maybeSingle();

        if (existing != null) {
          existingId = existing['id'];
        }
      }

      // If record exists, update it
      if (existingId != null) {
        await _client.from('stall_schedules').update({
          'open_time': scheduleData['open_time'],
          'close_time': scheduleData['close_time'],
          'is_open': scheduleData['is_open'],
        }).eq('id', existingId);
        print('Updated schedule for day $dayOfWeek with ID $existingId');
      }
      // Only create new records if the day is open
      else if (isOpen) {
        print('Creating new schedule for day $dayOfWeek (isOpen: $isOpen)');
        await _client.from('stall_schedules').insert({
          'stall_id': stallId,
          'day_of_week': dayOfWeek,
          'open_time': scheduleData['open_time'] ?? '09:00:00',
          'close_time': scheduleData['close_time'] ?? '17:00:00',
          'is_open': true, // Only create records for open days
          'specific_date': null
        });
      } else {
        // If the day is closed and doesn't exist, we don't need to create it
        print('Skipping creation of closed day $dayOfWeek');
      }
    } catch (e) {
      print('Error updating day schedule: $e');
      throw Exception('Failed to update schedule for $dayOfWeek: $e');
    }
  }

  // Batch update all days' schedules
  Future<void> updateWeekSchedule(
      int stallId, Map<String, Map<String, dynamic>> schedules) async {
    try {
      print('Starting batch week schedule update for stall ID: $stallId');

      // Log the input data for debugging
      print('Schedule data to update: $schedules');

      // For each day in the schedule
      for (final day in schedules.keys) {
        final Map<String, dynamic> daySchedule =
            Map<String, dynamic>.from(schedules[day]!);

        // Ensure required fields exist
        if (!daySchedule.containsKey('is_open')) {
          daySchedule['is_open'] = false;
        }

        if (!daySchedule.containsKey('open_time')) {
          daySchedule['open_time'] = '09:00:00';
        }

        if (!daySchedule.containsKey('close_time')) {
          daySchedule['close_time'] = '17:00:00';
        }

        // Log each day's data for debugging
        print('Updating $day schedule: $daySchedule');

        // Use updateDaySchedule which handles check for existing record
        await updateDaySchedule(stallId, day, daySchedule);
      }

      print('Weekly schedule updated successfully for stall $stallId');
    } catch (e) {
      print('Error updating week schedule: $e');
      throw Exception('Failed to update weekly schedule: $e');
    }
  }

  // Check if store should be open right now based on current day and time
  Future<bool> checkIfStoreIsOpenNow(int stallId) async {
    try {
      // Check for manual override first
      final manualOverride = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', 'override')
          .maybeSingle();

      // If manual override exists and is active, use its status
      if (manualOverride != null) {
        return manualOverride['is_open'] ?? false;
      }

      // Otherwise, check the schedule for the current day
      final now = DateTime.now();
      final currentDay = _getDayOfWeek(now.weekday);
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

      final schedule = await _client
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .eq('day_of_week', currentDay)
          .filter('specific_date', 'is', null)
          .maybeSingle();

      if (schedule == null) {
        return false; // No schedule found for today
      }

      if (!(schedule['is_open'] ?? false)) {
        return false; // Store is closed for this day
      }

      final openTime = schedule['open_time'] ?? '00:00:00';
      final closeTime = schedule['close_time'] ?? '23:59:59';

      // Check if current time is within operating hours
      return currentTime.compareTo(openTime) >= 0 &&
          currentTime.compareTo(closeTime) <= 0;
    } catch (e) {
      print('Error checking store open status: $e');
      return false; // Default to closed on error
    }
  }

  // Helper method to convert weekday number to day string
}
