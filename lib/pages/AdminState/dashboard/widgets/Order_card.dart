import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImprovedOrdersCard extends StatefulWidget {
  final int stallId;

  const ImprovedOrdersCard({super.key, required this.stallId});

  @override
  _ImprovedOrdersCardState createState() => _ImprovedOrdersCardState();
}

class _ImprovedOrdersCardState extends State<ImprovedOrdersCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedTimeframe = 'Monthly';
  final List<String> _timeframes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _errorMessage;

  late OrdersData _ordersData;

  // Add this property to your class
  final Map<String, OrdersData> _cachedData = {};
  final Map<String, DateTime> _cachedTimestamps = {};

  // Flag to prevent multiple simultaneous data fetches
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _ordersData = OrdersData();
    // Use a microtask to avoid blocking the UI during initial load
    Future.microtask(() => _fetchOrderData());
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  String _getIntervalForPeriod(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'daily':
        return '1 day';
      case 'weekly':
        return '7 days';
      case 'monthly':
        return '1 month';
      case 'yearly':
        return '1 year';
      default:
        return '1 month';
    }
  }

  Future<void> _fetchOrderData() async {
    // Prevent multiple simultaneous fetches
    if (_isFetching) return;
    _isFetching = true;

    // Use cached data if available with cache timeout of 5 minutes
    final cacheKey = '${widget.stallId}_$_selectedTimeframe';
    final now = DateTime.now();

    // Performance optimization: Check cache first before doing anything else
    if (_cachedData.containsKey(cacheKey) &&
        _cachedTimestamps[cacheKey] != null &&
        now.difference(_cachedTimestamps[cacheKey]!).inMinutes < 5) {
      if (mounted) {
        setState(() {
          _ordersData = _cachedData[cacheKey]!;
          _isLoading = false;
          _isFetching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Calculate date ranges based on selected timeframe
      final startDate = _getStartDate(now, _selectedTimeframe);
      final endDate = now;

      // Format dates for database
      final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Get previous date range for trend calculation
      final previousStartDate = _getStartDate(
          startDate.subtract(const Duration(days: 1)), _selectedTimeframe);
      final previousEndDate = startDate.subtract(const Duration(days: 1));
      final previousStartDateStr =
          DateFormat('yyyy-MM-dd').format(previousStartDate);
      final previousEndDateStr =
          DateFormat('yyyy-MM-dd').format(previousEndDate);

      // Use compute function to offload heavy data processing
      final results = await Future.wait([
        // Revenue data with response size limiting
        _supabase
            .rpc(
              'get_orders_revenue_by_period',
              params: {
                'p_start_date': startDateStr,
                'p_end_date': endDateStr,
                'p_stall_id': widget.stallId.toString(),
                'p_period': _getIntervalForPeriod(_selectedTimeframe),
              },
            )
            .timeout(const Duration(seconds: 5))
            .catchError((e) {
              print('Revenue data fetch error: $e');
              return <dynamic>[];
            }),

        // Current stats
        _supabase
            .rpc(
              'get_order_statistics',
              params: {
                'p_start_date': startDateStr,
                'p_end_date': endDateStr,
                'p_stall_id': widget.stallId.toString(),
              },
            )
            .timeout(const Duration(seconds: 3))
            .catchError((e) {
              print('Order stats fetch error: $e');
              return {
                'total_orders': 0,
                'average_order_value': 0.0,
                'total_revenue': 0.0
              };
            }),

        // Previous stats - fetch directly here instead of using a separate method
        _supabase
            .rpc(
              'get_order_statistics',
              params: {
                'p_start_date': previousStartDateStr,
                'p_end_date': previousEndDateStr,
                'p_stall_id': widget.stallId.toString(),
              },
            )
            .timeout(const Duration(seconds: 3))
            .catchError((e) {
              print('Previous stats fetch error: $e');
              return {
                'total_orders': 0,
                'average_order_value': 0.0,
                'total_revenue': 0.0
              };
            }),
      ]);

      final revenueData = results[0] as List<dynamic>;
      final orderStats = results[1] as Map<String, dynamic>;
      final previousOrderStats = results[2] as Map<String, dynamic>;

      print('Using yesterday stats instead: $previousOrderStats');

      // Avoid setState if widget is unmounted
      if (!mounted) {
        _isFetching = false;
        return;
      }

      // Process the data
      setState(() {
        _ordersData = OrdersData.fromDatabaseResponse(
          revenueData: _optimizeDataPoints(revenueData),
          currentStats: orderStats,
          previousStats: previousOrderStats,
          timeframe: _selectedTimeframe,
        );
        _isLoading = false;

        // Cache results
        _cachedData[cacheKey] = _ordersData;
        _cachedTimestamps[cacheKey] = now;
        _isFetching = false;
      });
    } catch (e) {
      print('Error details: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data. Please try again later.';
          _isLoading = false;
          _isFetching = false;
        });
      }
    }
  }

  // Helper method to optimize data points for chart rendering
  List<dynamic> _optimizeDataPoints(List<dynamic> originalData) {
    if (originalData.length <= 20) return originalData;

    // Sample data to reduce points for better performance
    final sampledData = <dynamic>[];
    final step = (originalData.length / 20).ceil();

    for (int i = 0; i < originalData.length; i += step) {
      if (i < originalData.length) {
        sampledData.add(originalData[i]);
      }
    }

    return sampledData;
  }

  DateTime _getStartDate(DateTime date, String timeframe) {
    switch (timeframe) {
      case 'Daily':
        return DateTime(date.year, date.month, date.day);
      case 'Weekly':
        // Go back to start of week (Monday)
        return date.subtract(Duration(days: date.weekday - 1));
      case 'Monthly':
        // First day of the month
        return DateTime(date.year, date.month, 1);
      case 'Yearly':
        // First day of the year
        return DateTime(date.year, 1, 1);
      default:
        return DateTime(date.year, date.month, 1);
    }
  }

  void _updateChartData() {
    _fetchOrderData();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
            child: Text(_errorMessage!, style: TextStyle(color: Colors.red))),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme, textTheme),
            const SizedBox(height: 24),
            _buildMetrics(colorScheme, textTheme),
            const SizedBox(height: 24),
            _buildChart(colorScheme),
            const SizedBox(height: 16),
            _buildTimeIndicator(colorScheme, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 3, // Give text more space
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Analytics',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Overview for stall #${widget.stallId}', // Shortened text
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: _buildTimeframeDropdown(colorScheme, textTheme),
        ),
      ],
    );
  }

  Widget _buildTimeframeDropdown(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6), // Smaller padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeframe,
          isDense: true, // More compact dropdown
          icon: Icon(Icons.keyboard_arrow_down, size: 16),
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != _selectedTimeframe) {
              setState(() {
                _selectedTimeframe = newValue;
                _updateChartData();
              });
            }
          },
          items: _timeframes.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMetrics(ColorScheme colorScheme, TextTheme textTheme) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricCard(
          label: 'Total Orders',
          value: _ordersData.totalOrders.toString(),
          trend:
              '${_ordersData.ordersTrend >= 0 ? '+' : ''}${_ordersData.ordersTrend.toStringAsFixed(1)}%',
          isPositive: _ordersData.ordersTrend >= 0,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        _MetricCard(
          label: 'Average Order',
          value: currencyFormat.format(_ordersData.averageOrder),
          trend:
              '${_ordersData.averageOrderTrend >= 0 ? '+' : ''}${_ordersData.averageOrderTrend.toStringAsFixed(1)}%',
          isPositive: _ordersData.averageOrderTrend >= 0,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildChart(ColorScheme colorScheme) {
    if (_ordersData.chartData.isEmpty) {
      return SizedBox(
        height: 160, // Reduced fixed height to prevent overflow
        child: Center(child: Text('No data available for this period')),
      );
    }

    // Calculate a reasonable Y max to prevent overflow
    double maxY = 0;
    for (var spot in _ordersData.chartData) {
      if (spot.y > maxY) maxY = spot.y;
    }

    // Add 10% margin to the top and ensure it's never zero
    maxY = maxY * 1.1;
    // Ensure maxY is never zero or too small
    if (maxY < 1) {
      maxY = 10; // Default value when data is all zeros or very small
    }

    // Calculate a safe horizontal interval that's never zero
    final double safeHorizontalInterval = maxY / 4 > 0 ? maxY / 4 : 2.5;

    return SizedBox(
      height: 160, // Fixed height to prevent overflow issues
      child: RepaintBoundary(
        // Improves performance by limiting repaints
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeHorizontalInterval, // Use safe interval
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: colorScheme.surfaceContainerHighest,
                    strokeWidth: 0.5,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Show fewer labels for better performance
                      if (value == 0 ||
                          value == maxY / 2 ||
                          value.round() == maxY.round()) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: _ordersData.chartData.length > 10
                        ? (_ordersData.chartData.length / 5).floor().toDouble()
                        : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 ||
                          index >= _ordersData.labels.length ||
                          (index %
                                      (((_ordersData.labels.length / 5) + 1)
                                          .floor()) !=
                                  0 &&
                              _ordersData.labels.length > 10)) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _ordersData.getXAxisLabel(index),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _ordersData.chartData,
                  isCurved: true,
                  curveSmoothness: 0.2, // Reduced for better performance
                  preventCurveOverShooting:
                      true, // Prevent curve from overshooting
                  color: colorScheme.primary,
                  barWidth: 2, // Thinner line for better performance
                  dotData: FlDotData(
                    show: _ordersData.chartData.length <
                        15, // Only show dots for smaller datasets
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: colorScheme.primary,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colorScheme.primary.withOpacity(0.1),
                    spotsLine: BarAreaSpotsLine(
                      show:
                          false, // No vertical lines from points for better performance
                    ),
                  ),
                ),
              ],
              minY: 0,
              maxY: maxY, // Set maximum Y value to prevent overflow
              clipData: FlClipData
                  .all(), // Ensure all data is clipped within the chart area
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(ColorScheme colorScheme, TextTheme textTheme) {
    String dateRangeText;
    switch (_selectedTimeframe) {
      case 'Daily':
        dateRangeText = DateFormat('d MMMM yyyy').format(DateTime.now());
        break;
      case 'Weekly':
        final startOfWeek =
            DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        dateRangeText =
            '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
        break;
      case 'Monthly':
        dateRangeText = DateFormat('MMMM yyyy').format(DateTime.now());
        break;
      case 'Yearly':
        dateRangeText = DateFormat('yyyy').format(DateTime.now());
        break;
      default:
        dateRangeText = DateFormat('MMMM yyyy').format(DateTime.now());
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              dateRangeText,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersData {
  List<FlSpot> chartData = [];
  int totalOrders = 0;
  double averageOrder = 0;
  List<String> labels = [];
  double ordersTrend = 0.0;
  double averageOrderTrend = 0.0;
  double totalRevenue = 0.0;

  OrdersData() {
    // Initialize with empty data
    chartData = [];
    totalOrders = 0;
    averageOrder = 0;
    labels = [];
    ordersTrend = 0.0;
    averageOrderTrend = 0.0;
    totalRevenue = 0.0;
  }

  factory OrdersData.fromDatabaseResponse({
    required List<dynamic> revenueData,
    required Map<String, dynamic> currentStats,
    required Map<String, dynamic> previousStats,
    required String timeframe,
  }) {
    final result = OrdersData();

    // Set metrics from current stats
    result.totalOrders = (currentStats['total_orders'] as num?)?.toInt() ?? 0;
    result.averageOrder =
        (currentStats['average_order_value'] as num?)?.toDouble() ?? 0.0;
    result.totalRevenue =
        (currentStats['total_revenue'] as num?)?.toDouble() ?? 0.0;

    // Calculate trends
    final prevTotalOrders =
        (previousStats['total_orders'] as num?)?.toInt() ?? 0;
    final prevAvgOrder =
        (previousStats['average_order_value'] as num?)?.toDouble() ?? 0.0;

    if (prevTotalOrders > 0) {
      result.ordersTrend =
          ((result.totalOrders - prevTotalOrders) / prevTotalOrders) * 100;
    } else if (result.totalOrders > 0) {
      result.ordersTrend = 100.0;
    }

    if (prevAvgOrder > 0) {
      result.averageOrderTrend =
          ((result.averageOrder - prevAvgOrder) / prevAvgOrder) * 100;
    } else if (result.averageOrder > 0) {
      result.averageOrderTrend = 100.0;
    }

    // Process chart data
    if (revenueData.isNotEmpty) {
      result.chartData = [];
      result.labels = [];

      for (int i = 0; i < revenueData.length; i++) {
        final item = revenueData[i];
        if (item != null && item['revenue'] != null && item['label'] != null) {
          final revenue = (item['revenue'] as num).toDouble();
          result.chartData.add(FlSpot(i.toDouble(), revenue));
          result.labels.add(_formatLabel(item['label'], timeframe));
        }
      }
    }

    return result;
  }

  static String _formatLabel(String rawLabel, String timeframe) {
    try {
      switch (timeframe) {
        case 'Daily':
          return DateFormat('HH:mm').format(DateTime.parse(rawLabel));
        case 'Weekly':
          return DateFormat('EEE').format(DateTime.parse(rawLabel));
        case 'Monthly':
          return DateFormat('d').format(DateTime.parse(rawLabel));
        case 'Yearly':
          return DateFormat('MMM').format(DateTime.parse(rawLabel));
        default:
          return rawLabel;
      }
    } catch (e) {
      print('Error formatting label: $e');
      return rawLabel;
    }
  }

  String getXAxisLabel(int index) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '';
  }
}
