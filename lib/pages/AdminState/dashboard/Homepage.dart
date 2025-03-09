import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'widgets/balance_card.dart';
import 'widgets/category_scroll.dart';
import 'widgets/profile_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/top_menu_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int? standId;
  const AdminDashboardScreen({super.key, required this.standId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late FoodService foodService;
  late Future<List<Menu>> menuFuture;
  final _supabase = Supabase.instance.client;
  double _currentBalance = 0;
  Map<String, List<double>> _revenueData = {
    'daily': [],
    'weekly': [],
    'monthly': [],
    'yearly': [],
  };
  bool _isLoadingRevenue = false;

  @override
  void initState() {
    super.initState();
    foodService = FoodService();
    menuFuture = _fetchMenus();
    _loadRevenueData();
  }

  /// Fetch menus and refresh the UI
  Future<List<Menu>> _fetchMenus() async {
    if (widget.standId != null) {
      return await foodService.getMenuByStanId(widget.standId!);
    }
    return [];
  }

  /// Load revenue data from Supabase
  Future<void> _loadRevenueData() async {
    if (widget.standId == null) return;

    setState(() {
      _isLoadingRevenue = true;
    });

    try {
      // Fetch daily revenue
      final dailyRevenue = await _fetchRevenueData('1 day', 7);
      final weeklyRevenue = await _fetchRevenueData('7 days', 7);
      final monthlyRevenue = await _fetchRevenueData('1 month', 7);
      final yearlyRevenue = await _fetchRevenueData('1 year', 7);

      // Calculate current balance - use longer time period for more data
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

      // Format dates in PostgreSQL format
      final startDateStr = DateFormat('yyyy-MM-dd').format(sixMonthsAgo);
      final endDateStr = DateFormat('yyyy-MM-dd').format(now);

      // Use the RPC function for consistency
      final statsData = await _supabase.rpc(
        'get_order_statistics',
        params: {
          'p_start_date': startDateStr,
          'p_end_date': endDateStr,
          'p_stall_id': widget.standId.toString(),
        },
      );

      // Extract total revenue from stats data (more reliable)
      double totalBalance = 0;
      if (statsData != null && statsData['total_revenue'] != null) {
        totalBalance = (statsData['total_revenue'] as num).toDouble();
        print('Total revenue from stats: $totalBalance');
      } else {
        // Fallback to direct query if RPC fails
        final currentRevenue = await _supabase
            .from('transactions')
            .select('total_amount')
            .eq('stall_id', widget.standId!)
            .gte('created_at', startDateStr)
            .lte('created_at', endDateStr)
            .neq('status', 'cancelled');

        for (var item in currentRevenue) {
          totalBalance += (item['total_amount'] as num).toDouble();
        }
        print('Total revenue from query: $totalBalance');
      }

      setState(() {
        _revenueData = {
          'daily': dailyRevenue,
          'weekly': weeklyRevenue,
          'monthly': monthlyRevenue,
          'yearly': yearlyRevenue,
        };
        _currentBalance = totalBalance;
        _isLoadingRevenue = false;
      });
    } catch (e) {
      print('Error loading revenue data: $e');
      setState(() {
        _isLoadingRevenue = false;
        // Set default values if there's an error
        _revenueData = {
          'daily': [0, 0, 0, 0, 0, 0, 0],
          'weekly': [0, 0, 0, 0, 0, 0, 0],
          'monthly': [0, 0, 0, 0, 0, 0, 0],
          'yearly': [0, 0, 0, 0, 0, 0, 0],
        };
      });
    }
  }

  /// Fetch revenue data for a specific period
  Future<List<double>> _fetchRevenueData(String period, int limit) async {
    // Calculate proper date range based on period
    DateTime endDate = DateTime.now();
    DateTime startDate;

    switch (period) {
      case '1 day':
        startDate = DateTime(endDate.year, endDate.month, endDate.day)
            .subtract(const Duration(hours: 24));
        break;
      case '7 days':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case '1 month':
        startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
        break;
      case '1 year':
        startDate = DateTime(endDate.year - 1, endDate.month, endDate.day);
        break;
      default:
        startDate = endDate.subtract(const Duration(days: 30));
    }

    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    print('Fetching $period data from $startDateStr to $endDateStr');

    final response = await _supabase.rpc(
      'get_orders_revenue_by_period',
      params: {
        'p_start_date': startDateStr,
        'p_end_date': endDateStr,
        'p_stall_id': widget.standId.toString(),
        'p_period': period,
      },
    );

    final List<double> result = [];
    if (response != null) {
      for (var item in response) {
        // Add a small baseline value to prevent flat charts when values are very small
        double value = (item['revenue'] as num).toDouble();
        // Ensure value is at least 1% of the max value in monthly/yearly views
        if (period == '1 month' || period == '1 year') {
          result.add(value > 0 ? value : 1.0);
        } else {
          result.add(value);
        }
      }
    }

    // Ensure we have at least the required data points by adding baseline values
    while (result.length < limit) {
      // Add small values instead of zeros to prevent flat charts
      result.insert(0, period == '1 day' ? 0.0 : 1.0);
    }

    // Limit to the most recent data points if we have more than needed
    if (result.length > limit) {
      return result.sublist(result.length - limit);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: RefreshIndicator(
        color: Colors.orange, // Warna indikator refresh
        backgroundColor: Colors.white, // Background indikator refresh
        strokeWidth: 3.0, // Ketebalan indikator refresh
        onRefresh: () async {
          setState(() {
            menuFuture = _fetchMenus();
          });
          await _loadRevenueData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
              bottom: 80), // Agar konten tidak ketutupan navbar
          child: SafeArea(
            child: Container(
              width: screenWidth * 0.9,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  ProfileHeaderWidget(
                    stallId: widget.standId,
                  ),
                  const SizedBox(height: 23),
                  const CustomSearchBarWidget(),
                  const SizedBox(height: 10),
                  const CategoryScroll(),
                  const SizedBox(height: 14),
                  BalanceCardWidget(
                    currentBalance:
                        _currentBalance, // Replace static value with dynamic data
                    currencyCode: 'IDR',
                    historicalData:
                        _revenueData, // Replace static map with dynamic data
                    primaryColor: const Color(0xFFFF542D),
                    backgroundColor: Colors.white,
                    onCardTap: () {},
                  ),
                  const SizedBox(height: 20),
                  if (widget.standId == null)
                    const Text(
                      'Stand ID is missing. Please select a valid stand.',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    )
                  else
                    FutureBuilder<List<Menu>>(
                      future: menuFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Colors.orange, // Warna loading
                                strokeWidth: 4.0, // Ketebalan loading
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text(
                            'No menus available.',
                            style: TextStyle(color: Colors.grey),
                          );
                        } else {
                          return TopMenuSection(
                            stanid: widget.standId,
                            foodService: foodService,
                            title: 'Featured Menu',
                            itemCount: snapshot.data!.length,
                            menus: snapshot.data!,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
