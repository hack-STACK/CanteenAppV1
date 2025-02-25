// import 'package:flutter/material.dart';
// import 'package:kantin/Models/student_models.dart';
// import 'package:kantin/Models/transaction_model.dart';
// import 'package:kantin/models/enums/transaction_enums.dart';
// import 'package:intl/intl.dart';
// import 'package:kantin/widgets/user_avatar.dart';
// import 'package:kantin/services/Database/order_service.dart';

// // OrderCard widget with addon support
// class OrderCard extends StatefulWidget {
//   final Transaction order;
//   final Function(TransactionStatus) onStatusUpdate;
//   final VoidCallback onTap;
//   final StudentModel? student;

//   const OrderCard({
//     super.key,
//     required this.order,
//     required this.onStatusUpdate,
//     required this.onTap,
//     this.student,
//   });

//   @override
//   State<OrderCard> createState() => _OrderCardState();
// }

// class _OrderCardState extends State<OrderCard> {
//   final OrderService _orderService = OrderService();
//   List<Map<String, dynamic>> _orderItems = [];
//   bool _isLoading = true;
//   bool _hasError = false;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     print('[OrderCard] Initializing OrderCard for Order #${widget.order.id}');
//     _fetchOrderDetails();
//   }

//   Future<void> _fetchOrderDetails() async {
//     print(
//         '[OrderCard] Starting to fetch details for Order #${widget.order.id}');

//     if (widget.order.details.isEmpty) {
//       print('[OrderCard] Warning: Order #${widget.order.id} has no details');
//       setState(() {
//         _isLoading = false;
//         _hasError = true;
//         _errorMessage = 'No order details found';
//       });
//       return;
//     }

//     try {
//       List<Map<String, dynamic>> items = [];

//       print(
//           '[OrderCard] Processing ${widget.order.details.length} items for Order #${widget.order.id}');

//       for (var detail in widget.order.details) {
//         print('[OrderCard] Processing detail: menuId=${detail.menuId}');

//         // Fetch food details
//         final foodItem = await _orderService.getFoodById(detail.menuId);

//         if (foodItem == null) {
//           print(
//               '[OrderCard] Error: Food item not found for menuId=${detail.menuId}');
//           continue;
//         }

//         Map<String, dynamic> itemMap = {
//           'food': foodItem,
//           'quantity': detail.quantity,
//           'unitPrice': detail.unitPrice,
//           'subtotal': detail.subtotal,
//           'notes': detail.notes,
//           'addons': <Map<String, dynamic>>[],
//         };

//         // Process addons
//         print(
//             '[OrderCard] Processing ${detail.addons.length} addons for item ${detail.menuId}');

//         for (var addon in detail.addons) {
//           final addonItem = await _orderService.getAddonById(addon.addonId);
//           if (addonItem != null) {
//             itemMap['addons'].add({
//               'name': addonItem.name,
//               'price': addon.subtotal,
//               'quantity': addon.quantity,
//             });
//           }
//         }

//         items.add(itemMap);
//       }

//       print(
//           '[OrderCard] Successfully processed ${items.length} items for Order #${widget.order.id}');

//       if (mounted) {
//         setState(() {
//           _orderItems = items;
//           _isLoading = false;
//           _hasError = false;
//         });
//       }
//     } catch (e, stackTrace) {
//       print('[OrderCard] Error processing Order #${widget.order.id}: $e');
//       print('[OrderCard] Stack trace: $stackTrace');

//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _hasError = true;
//           _errorMessage = 'Error loading order details';
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 _buildHeader(),
//                 const Divider(),
//                 _buildOrderItems(),
//                 _buildFooter(),
//               ],
//             ),
//     );
//   }

//   Widget _buildOrderItems() {
//     return ListView.builder(
//       itemCount: _orderItems.length,
//       itemBuilder: (context, index) {
//         final item = _orderItems[index];
//         return _buildOrderItem(item);
//       },
//     );
//   }

//   Widget _buildOrderItem(Map<String, dynamic> detail) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           children: [
//             // Menu item details
//             Row(
//               children: [
//                 // Menu image
//                 if (detail['food']?.photo != null)
//                   ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         detail['food']!.photo!,
//                         width: 50,
//                         height: 50,
//                         fit: BoxFit.cover,
//                       )),
//                 // Item info
//                 Expanded(
//                   child: Column(
//                     children: [
//                       Text(detail['food']?.foodName ?? 'Unknown Item'),
//                       Text('${detail['quantity']}x @ Rp${detail['unitPrice']}'),
//                       if (detail['notes']?.isNotEmpty ?? false)
//                         Text('Note: ${detail['notes']}'),
//                     ],
//                   ),
//                 ),
//                 Text('Rp${detail['subtotal']}'),
//               ],
//             ),
//             // Addon items
//             if (detail['addons']?.isNotEmpty ?? false) ...[
//               const Divider(height: 16),
//               ...detail['addons']!.map((addon) => Padding(
//                     padding: const EdgeInsets.only(left: 72),
//                     child: Row(
//                       children: [
//                         Text('+ ${addon['name']}'),
//                         Text('Rp${addon['price']}'),
//                       ],
//                     ),
//                   )),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).primaryColor.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   'Order #${widget.order.id}',
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//               const Spacer(),
//               _buildOrderTypeChip(widget.order.orderType),
//               const SizedBox(width: 8),
//               _buildStatusChip(context, widget.order),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               UserAvatar(studentId: widget.order.studentId, size: 40),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     if (widget.student != null) ...[
//                       Text(
//                         widget.student!.studentName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         widget.student!.studentPhoneNumber,
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                     Row(
//                       children: [
//                         Icon(Icons.access_time,
//                             size: 14, color: Colors.grey[600]),
//                         const SizedBox(width: 4),
//                         Text(
//                           DateFormat('MMM d, y • h:mm a')
//                               .format(widget.order.createdAt.toLocal()),
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (widget.order.orderType == OrderType.delivery &&
//                         widget.order.deliveryAddress != null) ...[
//                       const SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Icon(Icons.location_on,
//                               size: 14, color: Colors.grey[600]),
//                           const SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               widget.order.deliveryAddress!,
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 fontSize: 12,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFooter() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         border: Border(top: BorderSide(color: Colors.grey.shade200)),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Total Amount',
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 12,
//                 ),
//               ),
//               Text(
//                 NumberFormat.currency(
//                   locale: 'id',
//                   symbol: 'Rp ',
//                   decimalDigits: 0,
//                 ).format(widget.order.totalAmount),
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//           if (_showActionButton(widget.order))
//             Padding(
//               padding: const EdgeInsets.only(top: 12),
//               child: Row(
//                 children: [
//                   if (widget.order.status != TransactionStatus.cancelled)
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () =>
//                             widget.onStatusUpdate(TransactionStatus.cancelled),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.red,
//                           side: const BorderSide(color: Colors.red),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: const Text('Cancel'),
//                       ),
//                     ),
//                   if (widget.order.status != TransactionStatus.cancelled)
//                     const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () =>
//                           widget.onStatusUpdate(_getNextStatus(widget.order)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor:
//                             _getActionButtonColor(context, widget.order),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                       ),
//                       child: Text(_getActionButtonText(widget.order)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOrderTypeChip(OrderType type) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 8,
//         vertical: 4,
//       ),
//       decoration: BoxDecoration(
//         color: _getOrderTypeColor(type).withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             _getOrderTypeIcon(type),
//             size: 14,
//             color: _getOrderTypeColor(type),
//           ),
//           const SizedBox(width: 4),
//           Text(
//             type.name.toUpperCase(),
//             style: TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//               color: _getOrderTypeColor(type),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getOrderTypeIcon(OrderType type) {
//     return switch (type) {
//       OrderType.delivery => Icons.delivery_dining,
//       OrderType.pickup => Icons.shopping_bag,
//       OrderType.dine_in => Icons.restaurant,
//     };
//   }

//   Widget _buildStatusChip(BuildContext context, Transaction order) {
//     final (Color color, IconData icon, String label) = switch (order.status) {
//       TransactionStatus.pending => (Colors.orange, Icons.schedule, 'Pending'),
//       TransactionStatus.confirmed => (
//           Colors.blue,
//           Icons.check_circle,
//           'Confirmed'
//         ),
//       TransactionStatus.cooking => (Colors.amber, Icons.restaurant, 'Cooking'),
//       TransactionStatus.ready => (Colors.green, Icons.check_circle, 'Ready'),
//       TransactionStatus.delivering => (
//           Colors.purple,
//           Icons.delivery_dining,
//           'On Delivery'
//         ),
//       TransactionStatus.completed => (
//           Colors.green,
//           Icons.done_all,
//           'Completed'
//         ),
//       TransactionStatus.cancelled => (Colors.red, Icons.cancel, 'Cancelled'),
//     };

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 14, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 11,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   bool _showActionButton(Transaction order) {
//     return order.status != TransactionStatus.completed &&
//         order.status != TransactionStatus.cancelled;
//   }

//   TransactionStatus _getNextStatus(Transaction order) {
//     return switch ((order.status, order.orderType)) {
//       (TransactionStatus.pending, _) => TransactionStatus.confirmed,
//       (TransactionStatus.confirmed, _) => TransactionStatus.cooking,
//       (TransactionStatus.cooking, OrderType.delivery) =>
//         TransactionStatus.delivering,
//       (TransactionStatus.cooking, _) => TransactionStatus.ready,
//       (TransactionStatus.ready, _) => TransactionStatus.completed,
//       (TransactionStatus.delivering, _) => TransactionStatus.completed,
//       _ => order.status,
//     };
//   }

//   String _getActionButtonText(Transaction order) {
//     return switch ((order.status, order.orderType)) {
//       (TransactionStatus.pending, _) => 'Confirm Order',
//       (TransactionStatus.confirmed, _) => 'Start Cooking',
//       (TransactionStatus.cooking, OrderType.delivery) => 'Send for Delivery',
//       (TransactionStatus.cooking, OrderType.pickup) => 'Ready for Pickup',
//       (TransactionStatus.cooking, OrderType.dine_in) => 'Ready to Serve',
//       (TransactionStatus.delivering, _) => 'Mark Delivered',
//       (TransactionStatus.ready, _) => 'Mark Complete',
//       _ => 'Process Order',
//     };
//   }

//   Color _getActionButtonColor(BuildContext context, Transaction order) {
//     return switch (order.status) {
//       TransactionStatus.pending => Colors.blue,
//       TransactionStatus.confirmed => Colors.amber,
//       TransactionStatus.cooking => Colors.orange,
//       TransactionStatus.delivering => Colors.purple,
//       TransactionStatus.ready => Colors.green,
//       _ => Theme.of(context).primaryColor,
//     };
//   }

//   IconData _getPaymentIcon() {
//     return switch (widget.order.paymentStatus) {
//       PaymentStatus.unpaid => Icons.pending_outlined,
//       PaymentStatus.paid => Icons.payment,
//       PaymentStatus.refunded => Icons.reply,
//     };
//   }

//   Color _getOrderTypeColor(OrderType type) {
//     return switch (type) {
//       OrderType.delivery => Colors.blue,
//       OrderType.pickup => Colors.orange,
//       OrderType.dine_in => Colors.green,
//     };
//   }
// }