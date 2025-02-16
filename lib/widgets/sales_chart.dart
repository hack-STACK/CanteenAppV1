import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const SalesChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                    // ... Chart configuration
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
