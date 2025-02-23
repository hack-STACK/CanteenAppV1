// import 'package:flutter/material.dart';
// import 'package:kantin/models/enums/transaction_enums.dart';

// class OrderStatusBadge extends StatelessWidget {
//   final TransactionStatus status;
//   final OrderType orderType;

//   const OrderStatusBadge({
//     super.key,
//     required this.status,
//     required this.orderType,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final (color, icon, label) = _getStatusInfo();

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: _getBackgroundColor(),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: _getBorderColor()),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: color),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getBackgroundColor() {
//     return _getStatusColor().withAlpha(30); // Use withAlpha instead of withOpacity
//   }

//   Color _getBorderColor() {
//     return _getStatusColor().withAlpha(50); // Use withAlpha instead of withOpacity
//   }

//   (Color, IconData, String) _getStatusInfo() {
//     switch (status) {
//       case TransactionStatus.pending:
//         return (Colors.orange, Icons.hourglass_empty, 'Pending');
//       case TransactionStatus.confirmed:
//         switch (orderType) {
//           case OrderType.delivery:
//             return (Colors.blue, Icons.delivery_dining, 'On Delivery');
//           case OrderType.pickup:
//             return (Colors.green, Icons.shopping_bag, 'Ready for Pickup');
//           case OrderType.dine_in:
//             return (Colors.green, Icons.restaurant, 'Being Prepared');
//         }
//       case TransactionStatus.completed:
//         return (Colors.green, Icons.check_circle, 'Completed');
//       case TransactionStatus.cancelled:
//         return (Colors.red, Icons.cancel, 'Cancelled');
//       case TransactionStatus.rejected:
//         return (Colors.red, Icons.block, 'Rejected');
//     }
//   }
// }
