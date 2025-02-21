import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/orderItem.dart';
import 'package:kantin/models/enums/transaction_enums.dart';

class ModernOrderCard extends StatefulWidget {
  final Transaction order;
  final StudentModel? student;
  final Function(TransactionStatus) onStatusUpdate;
  final VoidCallback onTap;
  final List<OrderItem>? orderItems;
  final bool isLoading;

  const ModernOrderCard({
    super.key,
    required this.order,
    this.student,
    required this.onStatusUpdate,
    required this.onTap,
    this.orderItems,
    this.isLoading = false,
  });

  @override
  State<ModernOrderCard> createState() => _ModernOrderCardState();
}

class _ModernOrderCardState extends State<ModernOrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme, textTheme),
                if (!widget.isLoading) ...[
                  const Divider(height: 24),
                  _buildItems(colorScheme, textTheme),
                  const Divider(height: 24),
                  _buildFooter(colorScheme, textTheme),
                ] else ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getOrderTypeIcon(),
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${widget.order.id}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(colorScheme),
                ],
              ),
              if (widget.student != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      widget.student!.studentName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(widget.order.createdAt),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItems(ColorScheme colorScheme, TextTheme textTheme) {
    if (widget.orderItems == null || widget.orderItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.orderItems!.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: item.menu?.photo != null
                          ? DecorationImage(
                              image: NetworkImage(item.menu!.photo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: item.menu?.photo == null
                        ? Icon(Icons.restaurant,
                            color: colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menu?.foodName ?? 'Unknown Item',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${item.quantity}x ${currencyFormatter.format(item.menu?.price ?? 0)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        if ((widget.orderItems?.length ?? 0) > 2)
          Center(
            child: TextButton.icon(
              onPressed: widget.onTap,
              icon: const Icon(Icons.expand_more, size: 20),
              label: Text('${widget.orderItems!.length - 2} more items'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: textTheme.titleMedium,
            ),
            Text(
              currencyFormatter.format(widget.order.totalAmount),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        if (_canUpdateStatus(widget.order.status)) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onStatusUpdate(
                _getNextStatus(widget.order.status, widget.order.orderType),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_getActionButtonText()),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getOrderTypeIcon() {
    return switch (widget.order.orderType) {
      OrderType.delivery => Icons.delivery_dining,
      OrderType.pickup => Icons.takeout_dining,
      OrderType.dine_in => Icons.restaurant,
    };
  }

  Widget _buildStatusChip(ColorScheme colorScheme) {
    final (color, icon, label) =
        _getStatusInfo(widget.order.status, widget.order.orderType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (orderDate == today) {
      return 'Today ${DateFormat('HH:mm').format(dateTime)}';
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    }
    return DateFormat('dd MMM HH:mm').format(dateTime);
  }

  bool _canUpdateStatus(TransactionStatus status) {
    return status != TransactionStatus.completed &&
        status != TransactionStatus.cancelled;
  }

  TransactionStatus _getNextStatus(
      TransactionStatus currentStatus, OrderType orderType) {
    return switch ((currentStatus, orderType)) {
      (TransactionStatus.pending, _) => TransactionStatus.confirmed,
      (TransactionStatus.confirmed, _) => TransactionStatus.cooking,
      (TransactionStatus.cooking, OrderType.delivery) =>
        TransactionStatus.delivering,
      (TransactionStatus.cooking, _) => TransactionStatus.ready,
      (TransactionStatus.ready, _) => TransactionStatus.completed,
      (TransactionStatus.delivering, _) => TransactionStatus.completed,
      _ => currentStatus,
    };
  }

  String _getActionButtonText() {
    return switch ((widget.order.status, widget.order.orderType)) {
      (TransactionStatus.pending, _) => 'Confirm Order',
      (TransactionStatus.confirmed, _) => 'Start Cooking',
      (TransactionStatus.cooking, OrderType.delivery) => 'Send for Delivery',
      (TransactionStatus.cooking, OrderType.pickup) => 'Ready for Pickup',
      (TransactionStatus.cooking, OrderType.dine_in) => 'Ready to Serve',
      (TransactionStatus.delivering, _) => 'Mark Delivered',
      (TransactionStatus.ready, _) => 'Mark Complete',
      _ => 'Process Order',
    };
  }

  (Color, IconData, String) _getStatusInfo(
      TransactionStatus status, OrderType orderType) {
    return switch ((status, orderType)) {
      (TransactionStatus.pending, _) => (
          Colors.orange,
          Icons.schedule,
          'Pending'
        ),
      (TransactionStatus.confirmed, _) => (
          Colors.blue,
          Icons.thumb_up,
          'Confirmed'
        ),
      (TransactionStatus.cooking, _) => (
          Colors.amber,
          Icons.restaurant,
          'Cooking'
        ),
      (TransactionStatus.ready, OrderType.pickup) => (
          Colors.green,
          Icons.takeout_dining,
          'Ready for Pickup'
        ),
      (TransactionStatus.ready, OrderType.dine_in) => (
          Colors.green,
          Icons.restaurant_menu,
          'Ready to Serve'
        ),
      (TransactionStatus.ready, OrderType.delivery) => (
          Colors.green,
          Icons.delivery_dining,
          'Ready for Delivery'
        ),
      (TransactionStatus.delivering, _) => (
          Colors.purple,
          Icons.delivery_dining,
          'Delivering'
        ),
      (TransactionStatus.completed, _) => (
          Colors.green,
          Icons.check_circle,
          'Completed'
        ),
      (TransactionStatus.cancelled, _) => (
          Colors.red,
          Icons.cancel,
          'Cancelled'
        ),
    };
  }
}
