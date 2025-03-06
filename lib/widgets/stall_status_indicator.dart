import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';

class StallStatusIndicator extends StatelessWidget {
  final Stan stall;
  final bool isDetailed;

  const StallStatusIndicator({
    Key? key,
    required this.stall,
    this.isDetailed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: stall.isOpen ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          stall.isOpen ? 'Open Now' : 'Closed',
          style: TextStyle(
            fontSize: isDetailed ? 12 : 10,
            fontWeight: FontWeight.w500,
            color: stall.isOpen ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ],
    );
  }

  // Helper method to show next opening information
  static Widget nextOpeningInfo(Stan stall, String nextOpeningTime) {
    if (nextOpeningTime.isEmpty) return SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            Icons.event_available,
            size: 12,
            color: Colors.orange[700],
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              'Opens $nextOpeningTime',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[700],
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
