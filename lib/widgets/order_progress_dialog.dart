import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderProgressDialog extends StatelessWidget {
  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> progressHistory;

  const OrderProgressDialog({
    super.key,
    required this.order,
    required this.progressHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order Progress History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: progressHistory.map((progress) {
                    return TimelineTile(
                      alignment: TimelineAlign.start,
                      isFirst: progressHistory.indexOf(progress) == 0,
                      isLast: progressHistory.indexOf(progress) ==
                          progressHistory.length - 1,
                      indicatorStyle: IndicatorStyle(
                        width: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      beforeLineStyle: LineStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                      endChild: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progress['status'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, y h:mm a').format(
                                  DateTime.parse(progress['timestamp'])
                                      .toLocal()),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (progress['notes'] != null)
                              Text(
                                progress['notes'],
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
