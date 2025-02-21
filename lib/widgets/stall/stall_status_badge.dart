import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class StallStatusBadge extends StatelessWidget {
  final Stan stall;

  const StallStatusBadge({
    Key? key,
    required this.stall,
  }) : super(key: key);

  String _getTimeString(TimeOfDay? time) {
    if (time == null) return 'N/A';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentlyOpen = stall.isCurrentlyOpen();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentlyOpen
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentlyOpen ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isCurrentlyOpen ? 'Open' : 'Closed',
            style: TextStyle(
              color: isCurrentlyOpen ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (stall.openTime != null && stall.closeTime != null)
            Text(
              '${_getTimeString(stall.openTime)} - ${_getTimeString(stall.closeTime)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
