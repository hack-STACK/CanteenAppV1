import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/stall_detail_models.dart';

class StallInfoSection extends StatelessWidget {
  final Stan stall;
  final List<StallMetric> metrics;
  final Map<String, String> schedule;
  final List<String> amenities;
  final List<String> paymentMethods;

  const StallInfoSection({
    super.key,
    required this.stall,
    required this.metrics,
    required this.schedule,
    required this.amenities,
    required this.paymentMethods,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMetricsRow(),
        const Divider(),
        _buildScheduleSection(),
        const Divider(),
        _buildAmenitiesSection(),
        const Divider(),
        _buildPaymentSection(),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: metrics.map((metric) => _buildMetricItem(metric)).toList(),
      ),
    );
  }

  Widget _buildMetricItem(StallMetric metric) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: metric.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(metric.icon, color: metric.color),
        ),
        const SizedBox(height: 8),
        Text(
          metric.value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          metric.label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operating Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...schedule.entries.map((entry) {
            bool isToday = DateTime.now().weekday.toString() == entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  if (isToday)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: entry.value == 'Closed' ? Colors.red : null,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amenities.map((amenity) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(amenity),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paymentMethods.map((method) {
              IconData icon = _getPaymentIcon(method);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 8),
                    Text(method),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'qris':
        return Icons.qr_code;
      case 'e-wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }
}
