import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsTheme {
  static const Color primary = Color(0xFF0B4AF5);
  static const Color accent = Color(0xFFFF542D);
  static const Color background = Color(0xFFF8FAFF);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1F36);
  static const Color textSecondary = Color(0xFF6B7280);

  static const cardDecoration = BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.all(Radius.circular(24)),
    boxShadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );
}

class ImprovedOrdersCard extends StatefulWidget {
  const ImprovedOrdersCard({super.key});

  @override
  _ImprovedOrdersCardState createState() => _ImprovedOrdersCardState();
}

class _ImprovedOrdersCardState extends State<ImprovedOrdersCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedTimeframe = 'Monthly';
  final List<String> _timeframes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  // Enhanced data structure
  late OrdersData _ordersData;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _ordersData = OrdersData();
    _updateChartData();
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

  void _updateChartData() {
    setState(() {
      _ordersData.updateTimeframe(_selectedTimeframe);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AnalyticsTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetrics(),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 16),
            _buildTimeIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AnalyticsTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of order analytics',
              style: TextStyle(
                fontSize: 14,
                color: AnalyticsTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildTimeframeDropdown(),
      ],
    );
  }

  Widget _buildTimeframeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AnalyticsTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeframe,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AnalyticsTheme.textSecondary),
          style: const TextStyle(
            color: AnalyticsTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
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

  Widget _buildMetrics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricCard(
          label: 'Total Orders',
          value: _ordersData.totalOrders.toString(),
          trend: '+12.5%',
          isPositive: true,
        ),
        _MetricCard(
          label: 'Average Order',
          value: '\$${_ordersData.averageOrder}',
          trend: '-2.3%',
          isPositive: false,
        ),
      ],
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AnalyticsTheme.background,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _ordersData.getXAxisLabel(value.toInt()),
                    style: const TextStyle(
                      color: AnalyticsTheme.textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _ordersData.chartData,
              isCurved: true,
              color: AnalyticsTheme.accent,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AnalyticsTheme.accent.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AnalyticsTheme.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today,
                size: 16, color: AnalyticsTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              DateFormat('MMMM yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: AnalyticsTheme.textSecondary,
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

  const _MetricCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AnalyticsTheme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AnalyticsTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AnalyticsTheme.textPrimary,
            ),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrdersData {
  List<FlSpot> chartData = [];
  int totalOrders = 0;
  double averageOrder = 0;
  List<String> labels = [];

  void updateTimeframe(String timeframe) {
    // Simulate data update based on timeframe
    chartData = [
      FlSpot(0, 8),
      FlSpot(1, 12),
      FlSpot(2, 16),
      FlSpot(3, 14),
      FlSpot(4, 18),
      FlSpot(5, 22),
    ];
    totalOrders = 1234;
    averageOrder = 85.50;
    labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  }

  String getXAxisLabel(int index) {
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '';
  }
}
