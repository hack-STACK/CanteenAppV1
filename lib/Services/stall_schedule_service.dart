import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stall_schedule.dart';

class StallScheduleService {
  final _supabase = Supabase.instance.client;

  // Fetch stall schedules for a specific stall
  Future<List<StallSchedule>> getSchedulesForStall(int stallId) async {
    try {
      final response = await _supabase
          .from('stall_schedules')
          .select()
          .eq('stall_id', stallId)
          .order('day_of_week', ascending: true);

      return (response as List)
          .map((data) => StallSchedule.fromMap(data))
          .toList();
    } catch (e) {
      print("Error fetching stall schedules: $e");
      throw Exception('Failed to fetch stall schedules: $e');
    }
  }

  // Add or update a stall schedule
  Future<void> saveSchedule(StallSchedule schedule) async {
    try {
      if (schedule.id > 0) {
        // Update existing schedule
        await _supabase
            .from('stall_schedules')
            .update(schedule.toMap())
            .eq('id', schedule.id);
      } else {
        // Create new schedule
        await _supabase.from('stall_schedules').insert(schedule.toMap());
      }
    } catch (e) {
      print("Error saving stall schedule: $e");
      throw Exception('Failed to save stall schedule: $e');
    }
  }

  // Delete a stall schedule
  Future<void> deleteSchedule(int scheduleId) async {
    try {
      await _supabase.from('stall_schedules').delete().eq('id', scheduleId);
    } catch (e) {
      print("Error deleting stall schedule: $e");
      throw Exception('Failed to delete stall schedule: $e');
    }
  }
}
