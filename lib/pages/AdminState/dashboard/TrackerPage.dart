import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/Balance_card.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/Order_card.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/Stats_row.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TrackerScreen extends StatefulWidget {
  final int? stanId;

  const TrackerScreen({super.key, this.stanId});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  double _currentBalance = 0;
  String _errorMessage = '';
  Map<String, List<double>> _revenueData = {
    'daily': [],
    'weekly': [],
    'monthly': [],
    'yearly': [],
  };

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    if (widget.stanId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid stall ID';
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Calculate date ranges
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      // Fetch revenue data from Supabase with corrected parameter
      final response = await _supabase.rpc(
        'get_advanced_menu_revenue_tracker',
        params: {
          'p_start_date': startOfYear.toIso8601String().split('T')[0],
          'p_end_date': now.toIso8601String().split('T')[0],
          'p_filter_stall_id':
              widget.stanId.toString(), // Changed from p_filter_stall_name
          'p_filter_menu_name': null,
        },
      );

      // Since the response is directly a List, just cast it
      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response as List);

      // Process the data for the chart
      _processRevenueData(data);
    } catch (e) {
      print('Error loading revenue data: $e');
      setState(() {
        _errorMessage = 'Failed to load revenue data: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _processRevenueData(List<Map<String, dynamic>> data) {
    // Initialize arrays
    final List<double> dailyData = [];
    final List<double> weeklyData = [];
    final List<double> monthlyData = [];
    final List<double> yearlyData = [];

    // Calculate total revenue (current balance)
    double totalRevenue = 0;

    // Process data for different time periods
    // This is simplified - you might need to adjust based on actual data structure
    for (var item in data) {
      final double revenue = (item['total_revenue'] as num).toDouble();
      totalRevenue += revenue;

      // For simplicity, just add the revenue to the respective arrays
      // You may need more complex logic depending on your data structure
      if (dailyData.length < 7) dailyData.add(revenue);
      if (weeklyData.length < 7) weeklyData.add(revenue);
      if (monthlyData.length < 7) monthlyData.add(revenue);
      if (yearlyData.length < 7) yearlyData.add(revenue);
    }

    // Update state
    setState(() {
      _currentBalance = totalRevenue;
      _revenueData = {
        'daily': dailyData,
        'weekly': weeklyData,
        'monthly': monthlyData,
        'yearly': yearlyData,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 66, 28, 35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 47,
                                height: 47,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF542D),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your Tracker',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 12),
                        BalanceCardWidget(
                          currentBalance: _currentBalance,
                          currencyCode: 'IDR',
                          historicalData: _revenueData,
                          primaryColor: const Color(0xFFFF542D),
                          backgroundColor: Colors.white,
                          onCardTap: () {
                            // Refresh data on tap
                            _loadRevenueData();
                          },
                        ),
                        const SizedBox(height: 12),
                        StatsRow(
                          stallId: widget.stanId,
                        ),
                        const SizedBox(height: 12),
                        ImprovedOrdersCard(
                          stallId: widget.stanId!,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
