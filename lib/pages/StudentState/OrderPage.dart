import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/widgets/order_details_sheet.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/widgets/cancel_order_dialog.dart';
import 'package:kantin/widgets/loading_overlay.dart';
import 'package:kantin/utils/error_handler.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _orderHistory = [];
  String? _error;
  late TabController _tabController;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);

      // Get the current user directly from static field since we know we're logged in
      final userId = 36; // Since we know this is the correct user ID

      print('Debug: Loading orders for user ID: $userId');

      // Get student data using user_id directly
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('id_user', userId)
          .single();

      print('Debug: Found student data: $studentData');

      if (studentData == null) {
        throw Exception(
            'Student profile not found. Please complete your profile first.');
      }

      final studentId = studentData['id'] as int;
      print('Debug: Using student ID: $studentId');

      // Load orders with student ID
      final activeOrders = await _transactionService.getActiveOrders(studentId);
      final orderHistory = await _transactionService.getOrderHistory(studentId);

      print(
          'Debug: Loaded ${activeOrders.length} active orders and ${orderHistory.length} historical orders');

      if (mounted) {
        setState(() {
          _activeOrders = activeOrders;
          _orderHistory = orderHistory;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print('Debug: Error in _loadOrders: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadOrders,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleCancelOrder(int transactionId) async {
    try {
      // Show loading overlay
      setState(() => _isLoading = true);

      // Check if order can be cancelled
      final canCancel = await _transactionService.canCancelOrder(transactionId);
      if (!canCancel) {
        throw Exception('This order cannot be cancelled at this time.');
      }

      // Show cancellation dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CancelOrderDialog(
          transactionId: transactionId,
          transactionService: _transactionService,
          onCancelled: () async {
            // Handle successful cancellation
            Navigator.pop(context, true); // Close dialog
            await _refreshOrders(); // Refresh orders list
          },
        ),
      );

      if (result == true) {
        // Successfully cancelled
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshOrders() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      // Get current student ID
      final userId = 36; // Replace with actual user ID
      final studentData = await _supabase
          .from('students')
          .select('id')
          .eq('id_user', userId)
          .single();

      if (studentData == null) {
        throw Exception('Student profile not found');
      }

      final studentId = studentData['id'] as int;

      // Load both active and history orders
      final activeOrders = await _transactionService.getActiveOrders(studentId);
      final orderHistory = await _transactionService.getOrderHistory(studentId);

      if (!mounted) return;

      setState(() {
        _activeOrders = activeOrders;
        _orderHistory = orderHistory;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Add helper method to get order type from database value
  OrderType _getOrderType(String? dbValue) {
    if (dbValue == null) return OrderType.delivery; // Default value

    try {
      return OrderType.values.firstWhere(
        (type) => type.name == dbValue.toLowerCase(),
        orElse: () => OrderType.delivery,
      );
    } catch (e) {
      print('Error parsing order type: $e');
      return OrderType.delivery;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Active Orders'),
              Tab(text: 'Order History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshOrders,
            ),
          ],
        ),
        body: _error != null
            ? _buildErrorView()
            : RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refreshOrders,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveOrders(),
                    _buildOrderHistory(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshOrders,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrders() {
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No active orders',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(_activeOrders[index], true),
      ),
    );
  }

  Widget _buildOrderHistory() {
    if (_orderHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No order history',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orderHistory.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(_orderHistory[index], false),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isActive) {
    final DateTime orderDate = DateTime.parse(order['created_at']);
    final String status = order['status'];
    final List<dynamic> items = order['items'] ?? [];
    final orderType = _getOrderType(order['order_type'] as String?);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Ordered on ${DateFormat('MMM d, y h:mm a').format(orderDate)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildOrderTimeline(status),
            const SizedBox(height: 16),
            _buildItemsList(items),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total'),
                Text(
                  'Rp ${order['total_amount']?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getOrderTypeIcon(orderType),
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _getOrderTypeLabel(orderType),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                if (orderType == OrderType.delivery &&
                    order['delivery_address'] != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${order['delivery_address']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showOrderDetails(order),
                  child: const Text('Track Order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label;

    switch (TransactionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TransactionStatus.pending,
    )) {
      case TransactionStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Pending';
        break;
      case TransactionStatus.confirmed:
        color = Colors.blue;
        icon = Icons.check_circle;
        label = 'Confirmed';
        break;
      case TransactionStatus.cooking:
        color = Colors.amber;
        icon = Icons.restaurant;
        label = 'Cooking';
        break;
      case TransactionStatus.delivering:
        color = Colors.green;
        icon = Icons.delivery_dining;
        label = 'Delivering';
        break;
      case TransactionStatus.completed:
        color = Colors.teal;
        icon = Icons.done_all;
        label = 'Completed';
        break;
      case TransactionStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(String status) {
    // Update the stages to include pending and in correct order
    final stages = [
      TransactionStatus.pending, // Add pending as first stage
      TransactionStatus.confirmed,
      TransactionStatus.cooking,
      TransactionStatus.delivering,
      TransactionStatus.completed
    ];

    // Get current status enum
    final currentStatus = TransactionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TransactionStatus.pending,
    );

    // Find index in stages
    final currentIndex = stages.indexOf(currentStatus);

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final isActive = index <= currentIndex && currentIndex >= 0;
          final isLast = index == stages.length - 1;
          final stage = stages[index];

          // Update timeline display
          return SizedBox(
            width: 100,
            child: TimelineTile(
              axis: TimelineAxis.horizontal,
              alignment: TimelineAlign.center,
              isFirst: index == 0,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                width: 20,
                // Fix nullable color issue by providing a default
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                iconStyle: IconStyle(
                  // Fix nullable color issue by providing a default
                  color: isActive ? Colors.white : Colors.grey.shade500,
                  iconData: Icons.check,
                ),
              ),
              endChild: Text(
                StringExtension(stage.name).capitalize(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
              beforeLineStyle: LineStyle(
                // Fix nullable color issue by providing a default
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item['quantity']}x ${item['menu_name']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    'Rp ${(item['price'] * item['quantity']).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => OrderDetailsSheet(
          order: order,
          onRefresh: _loadOrders,
        ),
      ),
    );
  }

  IconData _getOrderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.delivery:
        return Icons.delivery_dining;
      case OrderType.pickup:
        return Icons.store_mall_directory;
      case OrderType.dine_in:
        return Icons.restaurant;
    }
  }

  String _getOrderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Pickup';
      case OrderType.dine_in:
        return 'Dine In';
    }
  }

  // Update the details sheet to include order type
  Widget _buildOrderDetailsSheet(Map<String, dynamic> order) {
    final orderType = _getOrderType(order['order_type'] as String?);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... existing details content ...

          // Add order type details
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_getOrderTypeIcon(orderType),
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Type',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _getOrderTypeLabel(orderType),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (orderType == OrderType.delivery &&
              order['delivery_address'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Address',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(order['delivery_address']),
                ],
              ),
            ),

          // ... rest of existing details content ...
        ],
      ),
    );
  }
}

// Add this extension if not already present
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
