import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class StallStatusIndicator extends StatelessWidget {
  final Stan stall;
  final bool isDetailed;
  final double? fontSize;

  const StallStatusIndicator({
    super.key,
    required this.stall,
    this.isDetailed = false,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOpen = stall.isOpen;
    final bool isManuallyOverridden = stall.isManuallyOpen;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDetailed ? 8 : 6,
        vertical: isDetailed ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isOpen
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              color: isOpen ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: isDetailed ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  // Static method to get the next opening information
  static Widget nextOpeningInfo(Stan stall, String nextOpeningTime) {
    if (stall.isOpen || nextOpeningTime.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Opens $nextOpeningTime',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
