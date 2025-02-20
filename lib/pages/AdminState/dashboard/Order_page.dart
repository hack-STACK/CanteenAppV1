import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Models/UsersModels.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/services/Database/order_service.dart';
import 'package:kantin/services/notification_service.dart';
import 'package:kantin/widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  final int stanId;

  const OrdersScreen({super.key, required this.stanId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService(); // Add this line
  final NotificationService _notificationService = NotificationService();

  final tabs = [
    (status: TransactionStatus.pending, label: 'Pending', icon: Icons.schedule),
    (status: TransactionStatus.confirmed, label: 'Confirmed', icon: Icons.thumb_up),
    (status: TransactionStatus.cooking, label: 'Cooking', icon: Icons.restaurant),
    (status: TransactionStatus.delivering, label: 'Delivering', icon: Icons.delivery_dining),
    (status: TransactionStatus.completed, label: 'Completed', icon: Icons.check_circle),
    (status: TransactionStatus.cancelled, label: 'Cancelled', icon: Icons.cancel),
  ];

  Map<TransactionStatus, int> _orderCounts = {};
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length + 1, vsync: this); // +1 for "All" tab
    _notificationService.initialize();
    _setupOrderListener();
  }

  void _setupOrderListener() {
    _orderService.getStallOrders(widget.stanId).listen(
      (orders) {
        _checkForNewOrders(orders);
      },
      onError: (error) {
        print('Error in order stream: $error');
      },
    );
  }

  void _checkForNewOrders(List<Transaction> newOrders) {
    if (!mounted) return;

    // Find new pending orders
    final pendingOrders = newOrders.where((order) => 
      order.status == TransactionStatus.pending &&
      !_orderCounts.containsKey(order.id)
    );

    // Show notifications for new orders
    for (final order in pendingOrders) {
      _notificationService.showOrderNotification(
        orderId: order.id,
        title: 'New Order #${order.id}',
        body: 'You have a new order waiting for confirmation',
      );
    }

    setState(() {
      _updateOrderCounts(newOrders);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Orders',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: _buildTabBar(),
              ),
            ),
          ],
          body: StreamBuilder<List<Transaction>>(
            stream: _orderService.getStallOrders(widget.stanId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data ?? [];
              _updateOrderCounts(orders);

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(orders), // "All" tab
                  ...tabs.map((tab) {
                    final filteredOrders = orders.where(
                      (order) => order.status == tab.status
                    ).toList();
                    return _buildOrdersList(filteredOrders);
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).primaryColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: [
          _buildTab('All', Icons.list_alt, _orderCounts.values.fold(0, (a, b) => a + b)),
          ...tabs.map((tab) => _buildTab(
            tab.label, // Changed from tab.status.label to tab.label
            tab.icon,
            _orderCounts[tab.status] ?? 0,
          )),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _updateOrderCounts(List<Transaction> orders) {
    _orderCounts = {};
    for (final order in orders) {
      _orderCounts[order.status] = (_orderCounts[order.status] ?? 0) + 1;
    }
  }

  Widget _buildOrdersList(List<Transaction> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return FutureBuilder<StudentModel?>(
          future: _orderService.getStudentById(order.studentId),
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final student = studentSnapshot.data;

            return OrderCard(
              key: ValueKey('order_${order.id}'),
              order: order,
              student: student,
              onStatusUpdate: (newStatus) => _handleOrderAction(order, newStatus),
              onTap: () => _showOrderDetails(order),
            );
          },
        );
      },
    );
  }

  Future<void> _handleOrderAction(Transaction order, TransactionStatus newStatus) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _orderService.updateOrderStatus(order.id, newStatus);
      
      // Send notification about status change
      final message = _getStatusChangeMessage(order, newStatus);
      await _orderService.sendOrderNotification(order.id, message);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getStatusChangeMessage(Transaction order, TransactionStatus newStatus) {
    return switch ((newStatus, order.orderType)) {
      (TransactionStatus.confirmed, _) => 
        'Order #${order.id} has been confirmed',
      (TransactionStatus.cooking, _) => 
        'Order #${order.id} is being prepared',
      (TransactionStatus.ready, OrderType.pickup) => 
        'Order #${order.id} is ready for pickup',
      (TransactionStatus.ready, OrderType.dine_in) => 
        'Order #${order.id} is ready to serve',
      (TransactionStatus.ready, OrderType.delivery) => 
        'Order #${order.id} is ready for delivery',
      (TransactionStatus.delivering, _) => 
        'Order #${order.id} is out for delivery',
      (TransactionStatus.completed, _) => 
        'Order #${order.id} has been completed',
      (TransactionStatus.cancelled, _) => 
        'Order #${order.id} has been cancelled',
      _ => 'Order #${order.id} status updated to ${newStatus.name}',
    };
  }

  Future<void> _handleUndoAction(Transaction order) async {
    final previousStatus = _getPreviousStatus(order.status);
    if (previousStatus != null) {
      await _handleOrderAction(order, previousStatus);
    }
  }

  TransactionStatus? _getPreviousStatus(TransactionStatus currentStatus) {
    switch (currentStatus) {
      case TransactionStatus.cooking:
        return TransactionStatus.pending;
      case TransactionStatus.delivering:
        return TransactionStatus.cooking;
      case TransactionStatus.completed:
        return TransactionStatus.delivering;
      default:
        return null;
    }
  }

  Future<void> _showOrderDetails(Transaction order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildModalHeader(order),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildOrderTimeline(order),
                    const Divider(height: 32),
                    _buildDetailedItems(order),
                    if (order.notes?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      _buildNotesSection(order),
                    ],
                    if (order.deliveryAddress?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 16),
                      _buildDeliverySection(order),
                    ],
                  ],
                ),
              ),
              if (order.status != TransactionStatus.completed &&
                  order.status != TransactionStatus.cancelled)
                _buildModalActions(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(Transaction order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Order Details #${order.id}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(Transaction order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Timeline',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Add timeline implementation here
      ],
    );
  }

  Widget _buildDetailedItems(Transaction order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Add items list with details
        ...order.details.map((detail) => _buildOrderItem(detail)),
        const SizedBox(height: 16),
        // Add total amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Rp ${order.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItem(TransactionDetail detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu image
                if (detail.menu?.photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      detail.menu!.photo!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.menu?.foodName ?? 'Unknown Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detail.quantity}x @ Rp ${detail.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (detail.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Note: ${detail.notes}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Subtotal
                Text(
                  'Rp ${detail.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // Show addons if any
            if (detail.addons?.isNotEmpty ?? false) ...[
              const Divider(height: 16),
              ...detail.addons!.map((addon) => Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+ ${addon.addon?.name ?? 'Unknown Addon'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Rp ${addon.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(Transaction order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(order.notes!),
      ],
    );
  }

  Widget _buildDeliverySection(Transaction order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Information',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(order.deliveryAddress!),
      ],
    );
  }

  TransactionStatus _getNextStatus(TransactionStatus currentStatus, OrderType orderType) {
    return switch ((currentStatus, orderType)) {
      (TransactionStatus.pending, _) => TransactionStatus.confirmed,
      (TransactionStatus.confirmed, _) => TransactionStatus.cooking,
      (TransactionStatus.cooking, OrderType.delivery) => TransactionStatus.delivering,
      (TransactionStatus.cooking, _) => TransactionStatus.ready,
      (TransactionStatus.ready, _) => TransactionStatus.completed,
      (TransactionStatus.delivering, _) => TransactionStatus.completed,
      _ => currentStatus,
    };
  }

  String _getActionButtonText(TransactionStatus status, OrderType orderType) {
    return switch ((status, orderType)) {
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

  Widget _buildStatusChip(Transaction order) {
    final (Color color, IconData icon, String label) = switch ((order.status, order.orderType)) {
      // Initial states
      (TransactionStatus.pending, _) => (Colors.orange, Icons.schedule, 'Pending Confirmation'),
      (TransactionStatus.confirmed, _) => (Colors.blue, Icons.thumb_up, 'Confirmed'),
      (TransactionStatus.cooking, _) => (Colors.amber, Icons.restaurant, 'Cooking'),
      
      // Ready state variations
      (TransactionStatus.ready, OrderType.pickup) => (Colors.green, Icons.takeout_dining, 'Ready for Pickup'),
      (TransactionStatus.ready, OrderType.dine_in) => (Colors.green, Icons.restaurant_menu, 'Ready to Serve'),
      (TransactionStatus.ready, OrderType.delivery) => (Colors.green, Icons.delivery_dining, 'Ready for Delivery'),
      
      // Delivering state variations
      (TransactionStatus.delivering, OrderType.delivery) => (Colors.purple, Icons.delivery_dining, 'Out for Delivery'),
      (TransactionStatus.delivering, OrderType.pickup) => (Colors.purple, Icons.delivery_dining, 'Processing'),
      (TransactionStatus.delivering, OrderType.dine_in) => (Colors.purple, Icons.delivery_dining, 'Processing'),
      
      // Final states
      (TransactionStatus.completed, _) => (Colors.green, Icons.check_circle, 'Completed'),
      (TransactionStatus.cancelled, _) => (Colors.red, Icons.cancel, 'Cancelled'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30), // Use withAlpha instead of withOpacity
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildModalActions(Transaction order) {
    if (order.status == TransactionStatus.completed ||
        order.status == TransactionStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _handleOrderAction(order, TransactionStatus.cancelled),
              child: const Text('Cancel Order'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _handleOrderAction(
                      order,
                      _getNextStatus(order.status, order.orderType)),
              child: Text(_getActionButtonText(order.status, order.orderType)),
            ),
          ),
        ],
      ),
    );
  }
}
