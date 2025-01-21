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
  List<FlSpot> _chartData = [];
  double _maxY = 20; // Adjust based on your data
  final List<String> _timeframes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _updateChartData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  void _updateChartData() {
    // Update your chart data based on the selected timeframe
    // Example data generation
    setState(() {
      _chartData = [
        FlSpot(0, 8),
        FlSpot(1, 10),
        FlSpot(2, 14),
        FlSpot(3, 15),
        FlSpot(4, 13),
        FlSpot(5, 10),
      ];
      _maxY = 20; // Adjust based on your data
    });
  }

  Widget _buildTimeframeDropdown() {
    return DropdownButton<String>(
      value: _selectedTimeframe,
      icon: const Icon(Icons.keyboard_arrow_down),
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
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: _chartData.length.toDouble() - 1,
        minY: 0,
        maxY: _maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _chartData,
            isCurved: true,
            color: const Color(0xFFFF542D),
            barWidth: 3,
            belowBarData: BarAreaData(show: true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Orders',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                _buildTimeframeDropdown(),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(height: 200, child: _buildChart()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(DateTime.now().year.toString(),
                    style: TextStyle(fontSize: 12)),
              ],
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
