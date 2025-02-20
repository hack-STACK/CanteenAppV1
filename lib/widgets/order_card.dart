import 'package:flutter/material.dart';
import 'package:kantin/Models/UsersModels.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kantin/widgets/merchant_order_details.dart';
import 'package:kantin/widgets/user_avatar.dart';
import 'package:kantin/services/Database/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/services/Database/transaction_detail_service.dart';
import 'package:kantin/models/transaction_addon_detail_model.dart';

class OrderCard extends StatefulWidget {
  final Transaction order;
  final Function(TransactionStatus) onStatusUpdate;
  final VoidCallback onTap;
  final StudentModel? student; // Add this line

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
    required this.onTap,
    this.student, // Add this line
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final TransactionService _transactionService = TransactionService();
  final TransactionDetailService _detailService = TransactionDetailService();
  final OrderService _orderService = OrderService();
  Transaction? _orderDetails;
  List<TransactionDetail>? _orderItems;
  StudentModel? _studentDetails;  // Change from UserModel to StudentModel
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      // Load transaction details with menu items
      final details = await _detailService.getTransactionDetails(widget.order.id.toString());
      final student = await _orderService.getStudentById(widget.order.studentId);
      
      if (mounted) {
        setState(() {
          _orderItems = List<TransactionDetail>.from(details);
          _studentDetails = student;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading order details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use _orderDetails instead of widget.order when available
    final orderData = _orderDetails ?? widget.order;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : InkWell(
              onTap: () => _showOrderDetails(context),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _buildOrderHeader(context, orderData),
                  const Divider(height: 1),
                  _buildOrderContent(context, orderData),
                  _buildOrderFooter(context, orderData),
                ],
              ),
            ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => MerchantOrderDetails(
          order: widget.order,
          onStatusUpdate: widget.onStatusUpdate,
        ),
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, Transaction order) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              _buildOrderTypeChip(order.orderType),
              const SizedBox(width: 8),
              _buildStatusChip(context, order),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              UserAvatar(studentId: order.studentId, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_studentDetails != null) ...[  // Use _studentDetails instead of widget.student
                      Text(
                        _studentDetails!.studentName,  // Use namaSiswa from StudentModel
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _studentDetails!.studentPhoneNumber,  // Use telp from StudentModel
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y • h:mm a').format(order.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (order.orderType == OrderType.delivery && 
                        order.deliveryAddress != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.deliveryAddress!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Widget _buildOrderTypeChip(OrderType type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _getOrderTypeColor(type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getOrderTypeIcon(type),
            size: 14,
            color: _getOrderTypeColor(type),
          ),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _getOrderTypeColor(type),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderContent(BuildContext context, Transaction order) {
    if (_orderItems == null || _orderItems!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No items in this order',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50], 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._orderItems!.map((item) => _buildItemRow(context, item)),
          if (order.notes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            _buildNotes(context, order),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, TransactionDetail item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.menu != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.menu?.photo != null
                  ? CachedNetworkImage(
                      imageUrl: item.menu!.photo!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildErrorWidget(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menu?.foodName ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${item.quantity}x @ ${NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(item.unitPrice)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                if (item.notes?.isNotEmpty ?? false)
                  Text(
                    item.notes!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (item.addons?.isNotEmpty ?? false)
                  ..._buildAddons(item.addons!),
              ],
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(item.subtotal),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAddons(List<TransactionAddon> addons) {
    return addons.map((addon) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 12,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${addon.addon?.name} (${addon.quantity}x)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(addon.addon!.price * addon.quantity),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.restaurant,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.error_outline,
        color: Colors.grey[400],
        size: 24,
      ),
    );
  }

  Widget _buildNotes(BuildContext context, Transaction order) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.note_alt, color: Colors.amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              order.notes!,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter(BuildContext context, Transaction order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (_showActionButton(order))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (order.status != TransactionStatus.cancelled)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onStatusUpdate(TransactionStatus.cancelled),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  if (order.status != TransactionStatus.cancelled)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.onStatusUpdate(_getNextStatus(order)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionButtonColor(context, order),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(_getActionButtonText(order)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getOrderTypeIcon(OrderType type) {
    return switch (type) {
      OrderType.delivery => Icons.delivery_dining,
      OrderType.pickup => Icons.shopping_bag,
      OrderType.dine_in => Icons.restaurant,
    };
  }

  Widget _buildStatusChip(BuildContext context, Transaction order) {
    final (Color color, IconData icon, String label) = switch (order.status) {
      TransactionStatus.pending => (Colors.orange, Icons.schedule, 'Pending'),
      TransactionStatus.confirmed => (Colors.blue, Icons.check_circle, 'Confirmed'),
      TransactionStatus.cooking => (Colors.amber, Icons.restaurant, 'Cooking'),
      TransactionStatus.ready => (Colors.green, Icons.check_circle, 'Ready'),
      TransactionStatus.delivering => (Colors.purple, Icons.delivery_dining, 'On Delivery'),
      TransactionStatus.completed => (Colors.green, Icons.done_all, 'Completed'),
      TransactionStatus.cancelled => (Colors.red, Icons.cancel, 'Cancelled'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _showActionButton(Transaction order) {
    return order.status != TransactionStatus.completed && 
           order.status != TransactionStatus.cancelled;
  }

  TransactionStatus _getNextStatus(Transaction order) {
    return switch ((order.status, order.orderType)) {
      (TransactionStatus.pending, _) => TransactionStatus.confirmed,
      (TransactionStatus.confirmed, _) => TransactionStatus.cooking,
      (TransactionStatus.cooking, OrderType.delivery) => TransactionStatus.delivering,
      (TransactionStatus.cooking, _) => TransactionStatus.ready,
      (TransactionStatus.ready, _) => TransactionStatus.completed,
      (TransactionStatus.delivering, _) => TransactionStatus.completed,
      _ => order.status,
    };
  }

  String _getActionButtonText(Transaction order) {
    return switch ((order.status, order.orderType)) {
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

  Color _getActionButtonColor(BuildContext context, Transaction order) {
    return switch (order.status) {
      TransactionStatus.pending => Colors.blue,
      TransactionStatus.confirmed => Colors.amber,
      TransactionStatus.cooking => Colors.orange,
      TransactionStatus.delivering => Colors.purple,
      TransactionStatus.ready => Colors.green,
      _ => Theme.of(context).primaryColor,
    };
  }

  IconData _getPaymentIcon() {
    return switch (widget.order.paymentStatus) {
      PaymentStatus.unpaid => Icons.pending_outlined,
      PaymentStatus.paid => Icons.payment,
      PaymentStatus.refunded => Icons.reply,
    };
  }

  Color _getOrderTypeColor(OrderType type) {
    return switch (type) {
      OrderType.delivery => Colors.blue,
      OrderType.pickup => Colors.orange,
      OrderType.dine_in => Colors.green,
    };
  }
}