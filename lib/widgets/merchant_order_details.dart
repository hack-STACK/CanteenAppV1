import 'package:flutter/material.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:kantin/widgets/user_avatar.dart';

class MerchantOrderDetails extends StatelessWidget {
  final Transaction order;
  final Function(TransactionStatus) onStatusUpdate;

  const MerchantOrderDetails({
    Key? key,
    required this.order,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineProgress(context),
                  _buildCustomerSection(context),
                  _buildOrderItems(context),
                  if (order.notes?.isNotEmpty ?? false)
                    _buildNotes(context),
                  if (order.orderType == OrderType.delivery)
                    _buildDeliveryInfo(context),
                  _buildPaymentSummary(context),
                ],
              ),
            ),
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Order info
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y • h:mm a').format(order.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildStatusChip(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineProgress(BuildContext context) {
    final stages = [
      (icon: Icons.receipt_long, label: 'Order Placed', done: true),
      (icon: Icons.thumb_up, label: 'Confirmed', done: _isStageReached(TransactionStatus.confirmed)),
      (icon: Icons.restaurant, label: 'Cooking', done: _isStageReached(TransactionStatus.cooking)),
      (icon: Icons.delivery_dining, label: 'On Delivery', done: _isStageReached(TransactionStatus.delivering)),
      (icon: Icons.check_circle, label: 'Completed', done: _isStageReached(TransactionStatus.completed)),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (var i = 0; i < stages.length; i++)
            TimelineTile(
              isFirst: i == 0,
              isLast: i == stages.length - 1,
              indicatorStyle: IndicatorStyle(
                width: 24,
                color: stages[i].done 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300 ?? Colors.grey,
                iconStyle: IconStyle(
                  color: stages[i].done 
                      ? Colors.white 
                      : Colors.grey.shade500 ?? Colors.grey,
                  iconData: stages[i].icon,
                ),
              ),
              beforeLineStyle: LineStyle(
                color: stages[i].done 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade300 ?? Colors.grey,
              ),
              endChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  stages[i].label,
                  style: TextStyle(
                    color: stages[i].done ? Colors.black : Colors.grey.shade600 ?? Colors.grey,
                    fontWeight: stages[i].done ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Items', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...order.details.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (item.menu?.photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.menu!.photo!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.menu?.foodName ?? 'Unknown Item'),
                      Text(
                        '${item.quantity}x @ ${NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(item.unitPrice)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(item.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    if (order.notes == null || order.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_alt, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.notes!),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context) {
    if (order.deliveryAddress == null || order.deliveryAddress!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(order.deliveryAddress!),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    final deliveryFee = order.orderType == OrderType.delivery ? 2000.0 : 0.0;
    final total = order.totalAmount + deliveryFee;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Subtotal', order.totalAmount),
          if (order.orderType == OrderType.delivery)
            _buildPriceRow('Delivery Fee', deliveryFee),
          const Divider(height: 24),
          _buildPriceRow('Total', total, isTotal: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getPaymentIcon(),
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                order.paymentStatus.name.toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon() {
    return switch (order.paymentStatus) {
      PaymentStatus.unpaid => Icons.pending_outlined,
      PaymentStatus.paid => Icons.payment,
      PaymentStatus.refunded => Icons.reply,
    };
  }

  Widget _buildStatusChip(BuildContext context) {
    final (Color color, IconData icon) = _getStatusDesign(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            order.status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.status == TransactionStatus.completed ||
        order.status == TransactionStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onStatusUpdate(TransactionStatus.cancelled),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('Cancel Order'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => onStatusUpdate(_getNextStatus()),
              child: Text(_getActionButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => Colors.orange,
      TransactionStatus.confirmed => Colors.blue,
      TransactionStatus.cooking => Colors.amber,
      TransactionStatus.delivering => Colors.purple,
      TransactionStatus.ready => Colors.green,
      TransactionStatus.completed => Colors.teal,
      TransactionStatus.cancelled => Colors.red,
    };
  }

  IconData _getStatusIcon(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => Icons.schedule,
      TransactionStatus.confirmed => Icons.thumb_up,
      TransactionStatus.cooking => Icons.restaurant,
      TransactionStatus.delivering => Icons.delivery_dining,
      TransactionStatus.ready => Icons.check_circle,
      TransactionStatus.completed => Icons.done_all,
      TransactionStatus.cancelled => Icons.cancel,
    };
  }

  (Color, IconData) _getStatusDesign(TransactionStatus status) {
    return (
      _getStatusColor(status),
      _getStatusIcon(status),
    );
  }

  bool _isStageReached(TransactionStatus stage) {
    final stages = [
      TransactionStatus.pending,
      TransactionStatus.confirmed,
      TransactionStatus.cooking,
      TransactionStatus.delivering,
      TransactionStatus.completed,
    ];
    
    final currentIndex = stages.indexOf(order.status);
    final stageIndex = stages.indexOf(stage);
    
    return currentIndex >= stageIndex;
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => 'Waiting for Confirmation',
      TransactionStatus.confirmed => 'Order Confirmed',
      TransactionStatus.cooking => 'Preparing Order',
      TransactionStatus.delivering => 'Out for Delivery',
      TransactionStatus.ready => 'Ready for Pickup',
      TransactionStatus.completed => 'Order Completed',
      TransactionStatus.cancelled => 'Order Cancelled',
    };
  }

  String _getStatusDescription(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => 'Your order is waiting to be confirmed by the restaurant',
      TransactionStatus.confirmed => 'The restaurant has confirmed your order',
      TransactionStatus.cooking => 'Your food is being prepared',
      TransactionStatus.delivering => 'Your order is on its way',
      TransactionStatus.ready => 'Your order is ready for pickup',
      TransactionStatus.completed => 'Order has been delivered/picked up',
      TransactionStatus.cancelled => 'This order has been cancelled',
    };
  }

  TransactionStatus _getNextStatus() {
    return switch (order.status) {
      TransactionStatus.pending => TransactionStatus.confirmed,
      TransactionStatus.confirmed => TransactionStatus.cooking,
      TransactionStatus.cooking => order.orderType == OrderType.delivery
          ? TransactionStatus.delivering
          : TransactionStatus.ready,
      TransactionStatus.delivering => TransactionStatus.completed,
      TransactionStatus.ready => TransactionStatus.completed,
      _ => order.status,
    };
  }

  String _getActionButtonText() {
    return switch (order.status) {
      TransactionStatus.pending => 'Confirm Order',
      TransactionStatus.confirmed => 'Start Cooking',
      TransactionStatus.cooking => order.orderType == OrderType.delivery
          ? 'Send for Delivery'
          : 'Mark as Ready',
      TransactionStatus.delivering => 'Mark as Delivered',
      TransactionStatus.ready => 'Mark as Completed',
      _ => 'Process Order',
    };
  }

  Widget _buildCustomerSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              UserAvatar(studentId: order.studentId, size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (order.orderType == OrderType.delivery) ...[
                      const Text(
                        'Delivery Location',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress ?? 'No address provided',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ] else if (order.orderType == OrderType.dine_in) ...[
                      const Text(
                        'Order Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dine In',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
