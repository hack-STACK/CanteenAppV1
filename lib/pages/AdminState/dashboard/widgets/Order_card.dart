import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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

  void printColorDetails() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    print('Primary Color: ${colorScheme.primary}');
    print('Surface Color: ${colorScheme.surface}');
    print('On Surface Color: ${colorScheme.onSurface}');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Orders',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Overview of order analytics',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _buildTimeframeDropdown(colorScheme, textTheme),
      ],
    );
  }

  Widget _buildTimeframeDropdown(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeframe,
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
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

  Widget _buildMetrics(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricCard(
          label: 'Total Orders',
          value: _ordersData.totalOrders.toString(),
          trend: '+12.5%',
          isPositive: true,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        _MetricCard(
          label: 'Average Order',
          value: '\$${_ordersData.averageOrder}',
          trend: '-2.3%',
          isPositive: false,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildChart(ColorScheme colorScheme) {
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
                color: colorScheme.surfaceVariant,
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
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
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
              color: colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(ColorScheme colorScheme, TextTheme textTheme) {
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
              DateFormat('MMMM yyyy').format(DateTime.now()),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
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
