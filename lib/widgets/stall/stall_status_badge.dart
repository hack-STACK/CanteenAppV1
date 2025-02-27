import 'package:flutter/material.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/utils/time_utils.dart'; // Import the new time utils

class StallStatusBadge extends StatelessWidget {
  final Stan stall;
  final bool showHours;
  final bool large;

  const StallStatusBadge({
    Key? key,
    required this.stall,
    this.showHours = false,
    this.large = false,
  }) : super(key: key);

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'N/A';

    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '${hour}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _getOpeningMessage() {
    if (stall.openTime == null) return '';

    // If manually closed, show different message
    if (!stall.isManuallyOpen) {
      return ' Closed today';
    }

    // Get next opening time info
    final nextOpeningInfo = TimeUtils.getNextOpeningTime(stall);
    if (nextOpeningInfo == null) return '';

    return ' Opens ${nextOpeningInfo.timeDescription}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = stall.isCurrentlyOpen();
    final bool isManualClosure = !stall.isManuallyOpen;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: isOpen
            ? Colors.green.withOpacity(0.8)
            : (isManualClosure
                ? Colors.orange.withOpacity(0.8)
                : Colors.red.withOpacity(0.8)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 10 : 8,
            height: large ? 10 : 8,
            decoration: BoxDecoration(
              color: isOpen
                  ? Colors.green[100]
                  : (isManualClosure ? Colors.orange[100] : Colors.red[100]),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'OPEN' : (isManualClosure ? 'CLOSED TODAY' : 'CLOSED'),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: large ? 14 : 12,
            ),
          ),
          if (!isOpen && !showHours) ...[
            const SizedBox(width: 4),
            Text(
              _getOpeningMessage(),
              style: TextStyle(
                color: Colors.white,
                fontSize: large ? 12 : 10,
              ),
            ),
          ],
          if (showHours &&
              stall.openTime != null &&
              stall.closeTime != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${_formatTime(stall.openTime)} - ${_formatTime(stall.closeTime)})',
              style: TextStyle(
                color: Colors.white,
                fontSize: large ? 12 : 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
