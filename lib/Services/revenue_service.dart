import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/models/revenue_data.dart';

class RevenueService {
  final _supabase = Supabase.instance.client;

  Future<List<RevenueData>> getRevenueData({
    required DateTime startDate,
    required DateTime endDate,
    int? stallId,
    String? menuName,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_advanced_menu_revenue_tracker',
        params: {
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
          'p_filter_stall_id': stallId,
          'p_filter_menu_name': menuName,
        },
      );

      if (response.error != null) {
        throw Exception(
            'Failed to fetch revenue data: ${response.error!.message}');
      }

      final List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(response as List);
      return rawData.map((item) => RevenueData.fromJson(item)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Process revenue data into different time periods for chart display
  Map<String, List<double>> processChartData(List<RevenueData> data) {
    final Map<String, List<double>> result = {
      'daily': [],
      'weekly': [],
      'monthly': [],
      'yearly': [],
    };

    // This is where you'd implement the logic to group data by day/week/month/year
    // For simplicity, this is a basic implementation:

    // Last 7 days
    final List<RevenueData> dailyData = data.take(7).toList();
    result['daily'] = dailyData.map((e) => e.totalRevenue).toList();

    // Similar processing for weekly, monthly, yearly
    // ...

    return result;
  }

  double calculateTotalRevenue(List<RevenueData> data) {
    return data.fold(0.0, (sum, item) => sum + item.totalRevenue);
  }
}
