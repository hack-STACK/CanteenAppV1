import 'package:flutter/material.dart';
import 'package:kantin/Models/orderItem.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/order_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:kantin/widgets/user_avatar.dart';

class MerchantOrderDetails extends StatefulWidget {
  // Changed to StatefulWidget
  final Transaction order;
  final Function(TransactionStatus) onStatusUpdate;
  final StudentModel? student;

  const MerchantOrderDetails({
    super.key,
    required this.order,
    required this.onStatusUpdate,
    this.student,
  });

  @override
  State<MerchantOrderDetails> createState() => _MerchantOrderDetailsState();
}

class _MerchantOrderDetailsState extends State<MerchantOrderDetails> {
  bool _isLoading = false;
  String? _error;
  List<OrderItem> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('DEBUG: Loading order details for Order #${widget.order.id}');
      print('DEBUG: Raw order details: ${widget.order.details}');

      if (widget.order.details.isEmpty) {
        print('DEBUG: Order details is empty. Fetching from service...');
        // Attempt to fetch order details from service
        final orderService = OrderService();
        final details = await orderService.getOrderItems(widget.order.id);

        if (details.isEmpty) {
          print('DEBUG: No items found in service');
          throw Exception('No items found for this order');
        }

        print('DEBUG: Found ${details.length} items from service');
        if (mounted) {
          setState(() {
            _orderItems = details;
            _isLoading = false;
          });
        }
        return;
      }

      print('DEBUG: Processing ${widget.order.details.length} order items');

      final orderItems = widget.order.details.map((detail) {
        print('DEBUG: Processing detail: $detail');

        // Extract addon information
        final addonsList = detail.addons?.map((addon) {
              print('DEBUG: Processing addon: $addon');
              return OrderAddonDetail(
                id: addon.id?.toString() ?? '',
                addonId: (addon.addonId as num?)?.toInt() ?? 0,
                addonName: addon.addonName ?? 'Unknown Addon',
                price: addon.price ?? 0,
                quantity: addon.quantity ?? 1,
                unitPrice: addon.unitPrice ?? 0,
                subtotal: addon.subtotal ?? 0,
              );
            }).toList() ??
            [];

        print('DEBUG: Processed ${addonsList.length} addons');

        return OrderItem(
          id: detail.id?.toString() ?? '',
          orderId: widget.order.id,
          menuId: detail.menuId,
          quantity: detail.quantity ?? 0,
          unitPrice: detail.unitPrice ?? 0,
          subtotal: detail.subtotal ?? 0,
          notes: detail.notes,
          menu: detail.menu,
          addons: addonsList,
          createdAt: widget.order.createdAt,
        );
      }).toList();

      print('DEBUG: Successfully processed ${orderItems.length} items');

      if (mounted) {
        setState(() {
          _orderItems = orderItems;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('DEBUG: Error occurred while loading order details:');
      print('DEBUG: Error: $e');
      print('DEBUG: Stack trace: $stack');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

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
          _buildStatusBanner(context), // New prominent status banner
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState(context)
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context),
                            _buildTimelineProgress(context),
                            _buildCustomerSection(context),
                            _buildOrderItems(context),
                            if (widget.order.notes?.isNotEmpty ?? false)
                              _buildNotes(context),
                            if (widget.order.orderType == OrderType.delivery)
                              _buildDeliveryInfo(context),
                            _buildPaymentSummary(context),
                            const SizedBox(
                                height: 100), // Bottom padding for FAB
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context) {
    final (color, label, icon) = _getStatusInfo(widget.order.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getStatusDescription(widget.order.status),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => 'New order waiting for confirmation',
      TransactionStatus.confirmed => 'Order has been confirmed',
      TransactionStatus.cooking => 'Food is being prepared',
      TransactionStatus.delivering => 'Order is out for delivery',
      TransactionStatus.ready => 'Order is ready for pickup',
      TransactionStatus.completed => 'Order has been completed',
      TransactionStatus.cancelled => 'Order has been cancelled',
    };
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
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
                        'Order #${widget.order.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, y • h:mm a')
                        .format(widget.order.createdAt),
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
      (
        icon: Icons.thumb_up,
        label: 'Confirmed',
        done: _isStageReached(TransactionStatus.confirmed)
      ),
      (
        icon: Icons.restaurant,
        label: 'Cooking',
        done: _isStageReached(TransactionStatus.cooking)
      ),
      (
        icon: Icons.delivery_dining,
        label: 'On Delivery',
        done: _isStageReached(TransactionStatus.delivering)
      ),
      (
        icon: Icons.check_circle,
        label: 'Completed',
        done: _isStageReached(TransactionStatus.completed)
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (var i = 0; i < stages.length; i++)
            TimelineTile(
              isFirst: i == 0,
              isLast: i == stages.length - 1,
              indicatorStyle: IndicatorStyle(
                width: 24,
                color: stages[i].done
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                iconStyle: IconStyle(
                  color: stages[i].done ? Colors.white : Colors.grey.shade500,
                  iconData: stages[i].icon,
                ),
              ),
              beforeLineStyle: LineStyle(
                color: stages[i].done
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              endChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  stages[i].label,
                  style: TextStyle(
                    color: stages[i].done ? Colors.black : Colors.grey.shade600,
                    fontWeight:
                        stages[i].done ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(BuildContext context) {
    if (_orderItems.isEmpty) {
      return _buildEmptyOrderState();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_orderItems.length} items',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orderItems.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) =>
                _buildOrderItemCard(context, _orderItems[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, OrderItem item) {
    final mainCoursePrice = item.menu?.price ?? 0.0;
    final mainCourseTotal = mainCoursePrice * item.quantity;
    final addonsTotal = item.addons?.fold<double>(
          0,
          (sum, addon) => sum + (addon.price * addon.quantity),
        ) ??
        0.0;
    final itemTotal = mainCourseTotal + addonsTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemImage(item),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemHeader(context, item),
                    if (item.notes?.isNotEmpty ?? false)
                      _buildItemNotes(item.notes!),
                    if (item.addons?.isNotEmpty ?? false)
                      _buildItemAddons(item.addons!),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Item Total: ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(itemTotal),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(OrderItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: item.menu?.photo != null
          ? Image.network(
              item.menu!.photo!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, _) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
                child: Icon(Icons.restaurant, color: Colors.grey.shade400),
              ),
            )
          : Container(
              width: 70,
              height: 70,
              color: Colors.grey.shade200,
              child: Icon(Icons.restaurant, color: Colors.grey.shade400),
            ),
    );
  }

  Widget _buildItemHeader(BuildContext context, OrderItem item) {
    final mainPrice = item.menu?.price ?? 0.0;
    final quantity = item.quantity;
    final mainCourseTotal = mainPrice * quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.menu?.foodName ?? 'Unknown Item',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.quantity}x',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Price: ${NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(mainPrice)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(mainCourseTotal),
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemNotes(String notes) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Notes: $notes',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildItemAddons(List<OrderAddonDetail> addons) {
    final totalAddonsPrice = addons.fold<double>(
      0,
      (sum, addon) => sum + (addon.price * addon.quantity),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle_outline, size: 16),
                SizedBox(width: 4),
                Text(
                  'Add-ons',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...addons.map((addon) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(
                                '${addon.addonName} (${addon.quantity}x)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(addon.price * addon.quantity),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add-ons Subtotal',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(totalAddonsPrice),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    if (widget.order.notes == null || widget.order.notes!.isEmpty) {
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
          Text(widget.order.notes!),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(BuildContext context) {
    final deliveryAddress =
        widget.student?.studentAddress ?? widget.order.deliveryAddress;

    if (deliveryAddress == null || deliveryAddress.isEmpty) {
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
                'Alamat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(deliveryAddress),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(BuildContext context) {
    // Calculate main course total
    final mainCourseTotal = _orderItems.fold<double>(
      0,
      (sum, item) => sum + ((item.menu?.price ?? 0) * item.quantity),
    );

    // Calculate addons total
    final addonsTotal = _orderItems.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.addons?.fold<double>(
                0,
                (addonSum, addon) => addonSum + (addon.price * addon.quantity),
              ) ??
              0),
    );

    final deliveryFee =
        widget.order.orderType == OrderType.delivery ? 2000.0 : 0.0;
    final subtotal = mainCourseTotal + addonsTotal;
    final total = subtotal + deliveryFee;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Payment Status Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor().withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_getPaymentIcon(), color: _getPaymentStatusColor()),
                const SizedBox(width: 8),
                Text(
                  'Payment Status: ${widget.order.paymentStatus.name.toUpperCase()}',
                  style: TextStyle(
                    color: _getPaymentStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Price Breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPriceRow(
                  'Main Course Total',
                  mainCourseTotal,
                  showDivider: true,
                ),
                _buildPriceRow(
                  'Add-ons Total',
                  addonsTotal,
                  showDivider: true,
                ),
                _buildPriceRow(
                  'Subtotal',
                  subtotal,
                  showDivider: true,
                  isSubtotal: true,
                ),
                if (widget.order.orderType == OrderType.delivery)
                  _buildPriceRow(
                    'Delivery Fee',
                    deliveryFee,
                    showDivider: true,
                  ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Total Amount',
                  total,
                  isTotal: true,
                ),
              ],
            ),
          ),
          // Payment Method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Payment Method:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.order.paymentMethod
                      .name, // Using enum's default name property
                  style: TextStyle(
                    color: _getPaymentMethodColor(widget.order.paymentMethod),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool showDivider = false,
    bool isTotal = false,
    bool isSubtotal = false,
  }) {
    final textStyle = isTotal
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )
        : isSubtotal
            ? const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )
            : TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textStyle),
              Text(
                NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(amount),
                style: isTotal
                    ? textStyle.copyWith(
                        color: Theme.of(context).primaryColor,
                      )
                    : textStyle,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.grey.shade200,
            height: 1,
          ),
      ],
    );
  }

  Color _getPaymentStatusColor() {
    return switch (widget.order.paymentStatus) {
      PaymentStatus.unpaid => Colors.orange,
      PaymentStatus.paid => Colors.green,
      PaymentStatus.refunded => Colors.red,
    };
  }

  IconData _getPaymentIcon() {
    return switch (widget.order.paymentStatus) {
      PaymentStatus.unpaid => Icons.pending_outlined,
      PaymentStatus.paid => Icons.payment,
      PaymentStatus.refunded => Icons.reply,
    };
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => Colors.green,
      PaymentMethod.e_wallet => Colors.blue,
      PaymentMethod.bank_transfer => Colors.purple,
      PaymentMethod.credit_card => Colors.orange,
    };
  }

  Widget _buildStatusChip(BuildContext context) {
    final (Color color, IconData icon) = _getStatusDesign(widget.order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            widget.order.status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (widget.order.status == TransactionStatus.completed ||
        widget.order.status == TransactionStatus.cancelled) {
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
              onPressed: () =>
                  widget.onStatusUpdate(TransactionStatus.cancelled),
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
              onPressed: () => widget.onStatusUpdate(_getNextStatus()),
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

  (Color, String, IconData) _getStatusInfo(TransactionStatus status) {
    return (
      _getStatusColor(status),
      status.label,
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

    final currentIndex = stages.indexOf(widget.order.status);
    final stageIndex = stages.indexOf(stage);

    return currentIndex >= stageIndex;
  }

  TransactionStatus _getNextStatus() {
    return switch (widget.order.status) {
      TransactionStatus.pending => TransactionStatus.confirmed,
      TransactionStatus.confirmed => TransactionStatus.cooking,
      TransactionStatus.cooking => widget.order.orderType == OrderType.delivery
          ? TransactionStatus.delivering
          : TransactionStatus.ready,
      TransactionStatus.delivering => TransactionStatus.completed,
      TransactionStatus.ready => TransactionStatus.completed,
      _ => widget.order.status,
    };
  }

  String _getActionButtonText() {
    return switch (widget.order.status) {
      TransactionStatus.pending => 'Confirm Order',
      TransactionStatus.confirmed => 'Start Cooking',
      TransactionStatus.cooking => widget.order.orderType == OrderType.delivery
          ? 'Send for Delivery'
          : 'Mark as Ready',
      TransactionStatus.delivering => 'Mark as Delivered',
      TransactionStatus.ready => 'Mark as Completed',
      _ => 'Process Order',
    };
  }

  Widget _buildCustomerSection(BuildContext context) {
    // Get delivery address from student model if available
    final deliveryAddress = widget.student?.studentAddress ??
        widget.order.deliveryAddress ??
        'No address';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(
              'Customer Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'customer_${widget.student?.id ?? "unknown"}',
                  child: widget.student != null
                      ? UserAvatar(
                          studentId: widget.student!.id,
                          size: 70,
                          showBorder: true,
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_outline,
                              size: 40, color: Colors.grey[400]),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: widget.student?.studentName ??
                            widget.order.studentName ??
                            'Unknown Customer',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.location_on,
                        label: deliveryAddress,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: widget.order.orderType == OrderType.delivery
                            ? Icons.delivery_dining
                            : Icons.restaurant,
                        label: widget.order.orderType.name.toUpperCase(),
                        color: widget.order.orderType == OrderType.delivery
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color ?? Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Order Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrderDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrderState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No items in this order',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
