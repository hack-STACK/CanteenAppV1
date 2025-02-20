import 'package:flutter/material.dart';
import 'package:kantin/Models/orderItem.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/services/Database/order_service.dart';
import 'package:kantin/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:kantin/widgets/OrderCard.dart'; // Add this import
import 'package:kantin/widgets/shimmer_loading.dart'; // Add this new import
import 'package:kantin/widgets/merchant_order_details.dart'; // Add this import

class OrdersScreen extends StatefulWidget {
  final int stanId;

  const OrdersScreen({super.key, required this.stanId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService(); // Add this line
  final NotificationService _notificationService = NotificationService();

  final tabs = [
    (status: TransactionStatus.pending, label: 'Pending', icon: Icons.schedule),
    (
      status: TransactionStatus.confirmed,
      label: 'Confirmed',
      icon: Icons.thumb_up
    ),
    (
      status: TransactionStatus.cooking,
      label: 'Cooking',
      icon: Icons.restaurant
    ),
    (
      status: TransactionStatus.delivering,
      label: 'Delivering',
      icon: Icons.delivery_dining
    ),
    (
      status: TransactionStatus.completed,
      label: 'Completed',
      icon: Icons.check_circle
    ),
    (
      status: TransactionStatus.cancelled,
      label: 'Cancelled',
      icon: Icons.cancel
    ),
  ];

  Map<TransactionStatus, int> _orderCounts = {};
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: tabs.length + 1, vsync: this); // +1 for "All" tab
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
        !_orderCounts.containsKey(order.id));

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
                    final filteredOrders = orders
                        .where((order) => order.status == tab.status)
                        .toList();
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
          _buildTab('All', Icons.list_alt,
              _orderCounts.values.fold(0, (a, b) => a + b)),
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
              onStatusUpdate: (newStatus) =>
                  _handleOrderAction(order, newStatus),
              onTap: () => _showOrderDetails(order),
            );
          },
        );
      },
    );
  }

  Future<void> _handleOrderAction(
      Transaction order, TransactionStatus newStatus) async {
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

  String _getStatusChangeMessage(
      Transaction order, TransactionStatus newStatus) {
    return switch ((newStatus, order.orderType)) {
      (TransactionStatus.confirmed, _) =>
        'Order #${order.id} has been confirmed',
      (TransactionStatus.cooking, _) => 'Order #${order.id} is being prepared',
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
    // Get student data first
    final student = await _orderService.getStudentById(order.studentId);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => MerchantOrderDetails(
          order: order,
          onStatusUpdate: (status) => _handleOrderAction(order, status),
          student: student, // Add the student parameter
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
                          '+ ${addon.addonName}', // Use addonName instead of addon?.name
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
    final (Color color, IconData icon, String label) =
        switch ((order.status, order.orderType)) {
      // Initial states
      (TransactionStatus.pending, _) => (
          Colors.orange,
          Icons.schedule,
          'Pending Confirmation'
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

      // Ready state variations
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

      // Delivering state variations
      (TransactionStatus.delivering, OrderType.delivery) => (
          Colors.purple,
          Icons.delivery_dining,
          'Out for Delivery'
        ),
      (TransactionStatus.delivering, OrderType.pickup) => (
          Colors.purple,
          Icons.delivery_dining,
          'Processing'
        ),
      (TransactionStatus.delivering, OrderType.dine_in) => (
          Colors.purple,
          Icons.delivery_dining,
          'Processing'
        ),

      // Final states
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
                  : () =>
                      _handleOrderAction(order, TransactionStatus.cancelled),
              child: const Text('Cancel Order'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _handleOrderAction(
                      order, _getNextStatus(order.status, order.orderType)),
              child: Text(_getActionButtonText(order.status, order.orderType)),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderPage extends StatefulWidget {
  final int stanId; // Add stanId field

  const OrderPage({super.key, required this.stanId}); // Update constructor

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TransactionService _transactionService = TransactionService();
  final OrderService _orderService = OrderService(); // Add this
  bool _isProcessing = false;

  Stream<List<Transaction>> _getOrderStream() {
    return _transactionService
        .subscribeToNewOrders(widget.stanId)
        .map((orders) {
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Add missing methods
  Future<void> _handleOrderStatus(
      Transaction order, TransactionStatus newStatus) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await _transactionService.updateOrderStatus(order.id, newStatus);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Order #${order.id} status updated to ${newStatus.name}'),
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

  Future<void> _showOrderDetails(Transaction order) async {
    // Get student data first
    final student = await _orderService.getStudentById(order.studentId);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => MerchantOrderDetails(
          order: order,
          onStatusUpdate: (status) => _handleOrderStatus(order, status),
          student: student, // Add the student parameter
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders', style: theme.textTheme.titleLarge),
            Text(
              'Today: ${DateFormat('EEEE, d MMMM').format(DateTime.now())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: StreamBuilder<List<Transaction>>(
          stream: _getOrderStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            final orders = snapshot.data ?? [];
            if (orders.isEmpty) {
              return _buildEmptyState();
            }

            return _buildOrdersList(orders);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStats,
        label: const Text('Order Stats'),
        icon: const Icon(Icons.analytics),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const ShimmerLoading(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'New orders will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Transaction> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        // Add date header if needed
        final bool showHeader = index == 0 ||
            !_isSameDay(
              orders[index - 1].createdAt,
              order.createdAt,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildDateHeader(order.createdAt),
            _buildOrderCard(order),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        DateFormat('EEEE, MMMM d').format(date),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildOrderCard(Transaction order) {
    return FutureBuilder<StudentModel?>(
      future: _orderService.getStudentById(order.studentId),
      builder: (context, studentSnapshot) {
        return FutureBuilder<List<OrderItem>>(
          future: _orderService.getOrderItems(order.id),
          builder: (context, itemsSnapshot) {
            return Hero(
              tag: 'order_${order.id}',
              child: ModernOrderCard(
                key: ValueKey('order_${order.id}'),
                order: order,
                student: studentSnapshot.data,
                orderItems: itemsSnapshot.data,
                isLoading:
                    itemsSnapshot.connectionState == ConnectionState.waiting,
                onStatusUpdate: (status) => _handleOrderStatus(order, status),
                onTap: () => _showOrderDetails(order),
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sort),
            title: const Text('Sort by'),
            trailing: DropdownButton<String>(
              value: 'newest',
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Newest first')),
                DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
                DropdownMenuItem(value: 'amount', child: Text('Amount')),
              ],
              onChanged: (value) {
                // Implement sorting
                Navigator.pop(context);
              },
            ),
          ),
          // Add more filter options
        ],
      ),
    );
  }

  void _showStats() {
    // Implement order statistics view
  }
}

class OrderCard extends StatefulWidget {
  final Transaction order;
  final StudentModel? student;
  final Function(TransactionStatus) onStatusUpdate;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.student,
    required this.onStatusUpdate,
    required this.onTap,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final OrderService _orderService = OrderService();
  List<OrderItem> _orderItems = [];
  bool _isLoading = true;
  String? _error;
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final items = await _orderService.getOrderItems(widget.order.id);

      if (mounted) {
        setState(() {
          _orderItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching order details: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load order items';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 24),
              _buildOrderContent(),
              const Divider(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getOrderTypeIcon(),
            color: Theme.of(context).primaryColor,
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 4),
              if (widget.student != null)
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.student!.studentName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(widget.order.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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

  Widget _buildOrderContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_error!, style: TextStyle(color: Colors.red[400])),
              TextButton(
                onPressed: _fetchOrderDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No items in this order'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._orderItems.take(3).map((item) => _buildOrderItemCard(item)),
        if (_orderItems.length > 3) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: widget.onTap,
              child: Text(
                '+ ${_orderItems.length - 3} more items',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item.menu?.photo != null
                  ? DecorationImage(
                      image: NetworkImage(item.menu!.photo!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
            ),
            child: item.menu?.photo == null
                ? Icon(Icons.restaurant, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menu?.foodName ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${item.quantity}x ${currencyFormatter.format(item.menu?.price ?? 0)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (item.addons?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.addons!
                        .map((addon) =>
                            '+ ${addon.addonName} (${addon.quantity}x)')
                        .join(', '),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (item.notes?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.notes}',
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
          Text(
            currencyFormatter.format(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Amount',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              currencyFormatter.format(widget.order.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_getActionButtonText(
                widget.order.status,
                widget.order.orderType,
              )),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip() {
    final (color, label) = _getStatusInfo(widget.order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  IconData _getOrderTypeIcon() {
    return switch (widget.order.orderType) {
      OrderType.delivery => Icons.delivery_dining,
      OrderType.pickup => Icons.takeout_dining,
      OrderType.dine_in => Icons.restaurant,
    };
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

  (Color, String) _getStatusInfo(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => (Colors.orange, 'Pending'),
      TransactionStatus.confirmed => (Colors.blue, 'Confirmed'),
      TransactionStatus.cooking => (Colors.amber, 'Cooking'),
      TransactionStatus.ready => (Colors.green, 'Ready'),
      TransactionStatus.delivering => (Colors.purple, 'Delivering'),
      TransactionStatus.completed => (Colors.green, 'Completed'),
      TransactionStatus.cancelled => (Colors.red, 'Cancelled'),
    };
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

  String _getActionButtonText(TransactionStatus status, OrderType orderType) {
    return switch ((status, orderType)) {
      (TransactionStatus.pending, _) => 'Confirm',
      (TransactionStatus.confirmed, _) => 'Start Cooking',
      (TransactionStatus.cooking, OrderType.delivery) => 'Send',
      (TransactionStatus.cooking, OrderType.pickup) => 'Ready',
      (TransactionStatus.cooking, OrderType.dine_in) => 'Serve',
      (TransactionStatus.delivering, _) => 'Complete',
      (TransactionStatus.ready, _) => 'Complete',
      _ => 'Process',
    };
  }
}
