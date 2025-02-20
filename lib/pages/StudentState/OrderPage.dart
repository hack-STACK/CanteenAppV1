import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/pages/StudentState/Stalldetailpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/widgets/order_details_sheet.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/widgets/cancel_order_dialog.dart';
import 'package:kantin/widgets/loading_overlay.dart';
import 'package:kantin/utils/error_handler.dart';
import 'package:kantin/widgets/rate_menu_dialog.dart';
import 'package:kantin/Services/Database/refund_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:kantin/widgets/rating_indicator.dart';
import 'package:kantin/widgets/review_history_tab.dart';

class OrderPage extends StatefulWidget {
  final int studentId;

  const OrderPage({super.key, required this.studentId});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  final TransactionService _transactionService = TransactionService();
  final RefundService _refundService = RefundService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  Timer? _refundCheckTimer;

  bool _isLoading = true;
  bool _isConnected = true;
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _orderHistory = [];
  String? _error;
  late TabController _tabController;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  StreamSubscription? _orderSubscription;

  String _currentSortField = 'created_at';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupOrderSubscription();
    _loadOrders();

    _authService.authStateChanges.listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });

    // Check for refunds every minute
    _refundCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refundService.checkAndProcessAutomaticRefunds(),
    );
  }

  void _setupOrderSubscription() {
    _orderSubscription?.cancel();
    _orderSubscription =
        _transactionService.subscribeToOrders(widget.studentId).listen(
      (orders) {
        if (!mounted) return;

        setState(() {
          _activeOrders = orders.where((order) {
            final status = order['status']?.toString().toLowerCase() ?? '';
            return !['completed', 'cancelled'].contains(status);
          }).toList();

          _orderHistory = orders.where((order) {
            final status = order['status']?.toString().toLowerCase() ?? '';
            return ['completed', 'cancelled'].contains(status);
          }).toList();

          _isConnected = true;
          _error = null;
        });
      },
      onError: (error) {
        _logger.error('Order subscription error', error);
        if (mounted) {
          setState(() {
            _isConnected = false;
            _error = error.toString();
          });
        }
      },
    );
  }

  Future<void> _handleOrdersUpdate(List<Map<String, dynamic>> orders) async {
    if (!mounted) return;

    try {
      setState(() {
        _activeOrders = orders
            .where((order) => !['completed', 'cancelled']
                .contains(order['status']?.toString().toLowerCase() ?? ''))
            .toList();

        _orderHistory = orders
            .where((order) => ['completed', 'cancelled']
                .contains(order['status']?.toString().toLowerCase() ?? ''))
            .toList();

        _isConnected = true;
        _error = null;
      });
    } catch (e) {
      _logger.error('Error updating orders', e);
      if (mounted) {
        setState(() {
          _isConnected = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _tabController.dispose();
    _refundCheckTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getStudentData() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final userData = await _userService.getUserByFirebaseUid(userId);
      if (userData == null) {
        throw Exception('User profile not found');
      }

      final response = await _supabase
          .from('students')
          .select()
          .eq('id_user', userData.id!)
          .maybeSingle();

      if (response == null) {
        throw Exception('Student profile not found');
      }

      return response;
    } catch (e) {
      throw Exception('Failed to get student data: ${e.toString()}');
    }
  }

  void _handleError(dynamic error,
      {String fallbackMessage = 'An error occurred'}) {
    final message = error is Exception ? error.toString() : fallbackMessage;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadOrders,
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    _setLoading(true);
    try {
      _logger.info('Loading orders for student ID: ${widget.studentId}');

      final allOrders =
          await _transactionService.getAllOrders(widget.studentId);

      if (mounted) {
        setState(() {
          _activeOrders = allOrders
              .where((order) => !['completed', 'cancelled']
                  .contains(order['status']?.toString().toLowerCase() ?? ''))
              .toList();

          _orderHistory = allOrders
              .where((order) => ['completed', 'cancelled']
                  .contains(order['status']?.toString().toLowerCase() ?? ''))
              .toList();

          _error = null;
        });
      }
    } catch (e, stack) {
      _logger.error('Error loading orders', e, stack);
      _handleError(e);
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleCancelOrder(int transactionId) async {
    try {
      final orderData = await _supabase
          .from('transactions')
          .select('total_amount, payment_status')
          .eq('id', transactionId)
          .single();

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CancelOrderDialog(
          transactionId: transactionId,
          transactionService: _transactionService,
          onCancelled: () async {
            Navigator.pop(context, true);
            await _refreshOrders();
          },
          orderAmount: (orderData['total_amount'] as num).toDouble(),
          isPaid: orderData['payment_status'] == 'paid',
        ),
      );

      if (result == true) {
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

      _logger.info('Refreshing orders for student ID: ${widget.studentId}');

      final activeOrders =
          await _transactionService.getActiveOrders(widget.studentId);
      final orderHistory =
          await _transactionService.getOrderHistory(widget.studentId);

      if (!mounted) return;

      setState(() {
        _activeOrders = activeOrders;
        _orderHistory = orderHistory;
        _error = null;
      });
    } catch (e) {
      _logger.error('Error refreshing orders', e);
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

  OrderType _getOrderType(String? dbValue) {
    if (dbValue == null) return OrderType.delivery;

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

  void _showRatingDialog(Map<String, dynamic> menuItem) {
    final int? menuId = menuItem['id'];

    if (menuId == null) {
      print('Debug - Menu item data: $menuItem');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot rate this item: Menu ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RateMenuDialog(
        menuName: menuItem['menu_name'] ?? 'Unknown Item',
        menuId: menuId,
      ),
    );
  }

  void _showRefundDetails(int transactionId) async {
    try {
      final refunds =
          await _refundService.getRefundsByTransactionId(transactionId);
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Refund History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              if (refunds.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No refund history available'),
                )
              else
                SizedBox(
                  height: 200, // Set a fixed height for the ListView
                  child: ListView.builder(
                    itemCount: refunds.length,
                    itemBuilder: (context, index) {
                      final refund = refunds[index];
                      return Dismissible(
                        key: Key(refund['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                'Do you want to remove this refund record?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          try {
                            await _refundService.deleteRefund(refund['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refund record removed'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to remove record: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: ListTile(
                          title: Text(refund['reason'] ?? 'No reason provided'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('MMM d, y h:mm a').format(
                                    DateTime.parse(refund['created_at'])),
                              ),
                              if (refund['notes'] != null)
                                Text(
                                  refund['notes'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: _buildRefundStatusChip(refund['status']),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading refund history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRefundStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      case 'processed':
        color = Colors.blue;
        label = 'Processed';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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
            isScrollable: true,
            tabs: const [
              Tab(text: 'Active Orders'),
              Tab(text: 'Order History'),
              Tab(text: 'Reviews'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
            ),
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
                    ReviewHistoryTab(),
                  ],
                ),
              ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sort Orders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  _buildSortOption(
                    context,
                    setState,
                    'Date',
                    'created_at',
                    Icons.calendar_today,
                  ),
                  _buildSortOption(
                    context,
                    setState,
                    'Amount',
                    'total_amount',
                    Icons.attach_money,
                  ),
                  _buildSortOption(
                    context,
                    setState,
                    'Status',
                    'status',
                    Icons.info_outline,
                  ),
                  _buildSortOption(
                    context,
                    setState,
                    'Order Type',
                    'order_type',
                    Icons.local_shipping,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    StateSetter setState,
    String label,
    String field,
    IconData icon,
  ) {
    final bool isSelected = _currentSortField == field;

    return ListTile(
      leading:
          Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).primaryColor,
            )
          : null,
      selected: isSelected,
      onTap: () {
        setState(() {
          if (_currentSortField == field) {
            _sortAscending = !_sortAscending;
          } else {
            _currentSortField = field;
            _sortAscending = true;
          }
        });

        _sortOrders();
        Navigator.pop(context);
      },
    );
  }

  void _sortOrders() {
    setState(() {
      final comparator = (Map<String, dynamic> a, Map<String, dynamic> b) {
        dynamic valueA = a[_currentSortField];
        dynamic valueB = b[_currentSortField];

        // Handle special cases
        if (_currentSortField == 'created_at') {
          valueA = DateTime.parse(valueA);
          valueB = DateTime.parse(valueB);
        } else if (_currentSortField == 'total_amount') {
          valueA = (valueA as num).toDouble();
          valueB = (valueB as num).toDouble();
        }

        // Handle null values
        if (valueA == null) return _sortAscending ? -1 : 1;
        if (valueB == null) return _sortAscending ? 1 : -1;

        // Custom sorting for status
        if (_currentSortField == 'status') {
          final statusOrder = {
            'pending': 0,
            'confirmed': 1,
            'cooking': 2,
            'ready': 3,
            'delivering': 4,
            'completed': 5,
            'cancelled': 6,
          };
          valueA = statusOrder[valueA.toLowerCase()] ?? -1;
          valueB = statusOrder[valueB.toLowerCase()] ?? -1;
        }

        int comparison;
        if (valueA is DateTime) {
          comparison = valueA.compareTo(valueB);
        } else if (valueA is num) {
          comparison = valueA.compareTo(valueB);
        } else {
          comparison = valueA.toString().compareTo(valueB.toString());
        }

        return _sortAscending ? comparison : -comparison;
      };

      _activeOrders.sort(comparator);
      _orderHistory.sort(comparator);
    });

    // Show a confirmation snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sorted by ${_currentSortField.replaceAll('_', ' ').toLowerCase()} '
            '(${_sortAscending ? 'ascending' : 'descending'})',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Connection lost\nTap to retry',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setupOrderSubscription,
              child: const Text('Reconnect'),
            ),
          ],
        ),
      );
    }

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
            _buildItemsList(items, order), // Pass the order object here
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
            if (order['status'] == 'cancelled') ...[
              const Divider(),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _refundService.getRefundsByTransactionId(order['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final refunds = snapshot.data ?? [];
                  if (refunds.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('No refund information available'),
                    );
                  }

                  final latestRefund = refunds.first; // Most recent refund
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Refund Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildRefundStatusChip(latestRefund['status']),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, y h:mm a').format(
                                  DateTime.parse(latestRefund['created_at'])),
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        if (latestRefund['notes'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            latestRefund['notes'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showRefundDetails(order['id']),
                      tooltip: 'View Refund History',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final currentStatus = TransactionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TransactionStatus.pending,
    );

    final (Color color, IconData icon, String label) = switch (currentStatus) {
      TransactionStatus.pending => (Colors.orange, Icons.pending, 'Pending'),
      TransactionStatus.confirmed => (
          Colors.blue,
          Icons.check_circle,
          'Confirmed'
        ),
      TransactionStatus.cooking => (Colors.amber, Icons.restaurant, 'Cooking'),
      TransactionStatus.delivering => (
          Colors.green,
          Icons.delivery_dining,
          'Delivering'
        ),
      TransactionStatus.ready => (Colors.green, Icons.check_circle, 'Ready'),
      TransactionStatus.completed => (Colors.teal, Icons.done_all, 'Completed'),
      TransactionStatus.cancelled => (Colors.red, Icons.cancel, 'Cancelled'),
    };

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
    final stages = [
      TransactionStatus.pending,
      TransactionStatus.confirmed,
      TransactionStatus.cooking,
      TransactionStatus.delivering,
      TransactionStatus.completed
    ];

    final currentStatus = TransactionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == status.toLowerCase(),
      orElse: () => TransactionStatus.pending,
    );

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

          return SizedBox(
            width: 100,
            child: TimelineTile(
              axis: TimelineAxis.horizontal,
              alignment: TimelineAlign.center,
              isFirst: index == 0,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                width: 20,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                iconStyle: IconStyle(
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

  Widget _buildItemsList(List<dynamic> items, Map<String, dynamic> order) {
    if (items.isEmpty) {
      _logger.warn('No items found for order ${order['id']}');
      return const Text('No items in this order');
    }

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
        ...items.map((item) {
          _logger.debug('Processing item: $item');

          final quantity = item['quantity'] ?? 1;
          final menuName = item['menu']?['food_name'] ?? 'Unknown Item';

          double itemPrice = 0.0;
          if (item['menu']?['price'] != null) {
            itemPrice = (item['menu']['price'] as num).toDouble() * quantity;
          }

          final menuId = item['menu']?['id'] ?? item['menu_id'];

          if (menuId == null) {
            print(
                "[OrderPage] Warning: Missing menu ID for item in order ${order['id']}");
            return const SizedBox.shrink();
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: RatingService().getMenuRatingSummary(menuId),
            builder: (context, ratingSnapshot) {
              if (ratingSnapshot.hasError) {
                print("[OrderPage] Rating error: ${ratingSnapshot.error}");
                return const SizedBox.shrink();
              }

              final rating = ratingSnapshot.data?['average'] ?? 0.0;
              final ratingCount = ratingSnapshot.data?['count'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${quantity}x $menuName',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (ratingCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: RatingIndicator(
                                rating: rating,
                                ratingCount: ratingCount,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Rp ${itemPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (_isOrderCompleted(order)) ...[
                          const SizedBox(width: 8),
                          _buildRatingButton(menuId, menuName),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRatingButton(int menuId, String menuName) {
    return FutureBuilder<bool>(
      future: RatingService().hasUserRatedMenu(menuId),
      builder: (context, hasRatedSnapshot) {
        if (hasRatedSnapshot.hasError) {
          print("[OrderPage] Rating check error: ${hasRatedSnapshot.error}");
          return const SizedBox.shrink();
        }

        final hasRated = hasRatedSnapshot.data ?? false;

        return IconButton(
          icon: Icon(
            hasRated ? Icons.star : Icons.star_border,
            color: hasRated ? Colors.amber : null,
          ),
          onPressed: hasRated
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have already rated this item'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              : () {
                  final menuData = {
                    'id': menuId,
                    'menu_name': menuName,
                  };
                  _showRatingDialog(menuData);
                },
          tooltip: hasRated ? 'Already rated' : 'Rate this item',
          iconSize: 20,
        );
      },
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

  Future<int?> _getCurrentStudentId() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final userData = await _userService.getUserByFirebaseUid(userId);
      if (userData == null) {
        throw Exception('User profile not found');
      }

      final studentData = await _supabase
          .from('students')
          .select('students.id')
          .eq('id_user', userData.id!)
          .maybeSingle();

      if (studentData == null) {
        throw Exception('Student profile not found');
      }

      return studentData['id'] as int;
    } catch (e) {
      _logger.error('Error getting current student ID', e);
      return null;
    }
  }

  void showOrderDetails(Map<String, dynamic> order) {
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

  IconData getOrderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.delivery:
        return Icons.delivery_dining;
      case OrderType.pickup:
        return Icons.store_mall_directory;
      case OrderType.dine_in:
        return Icons.restaurant;
    }
  }

  String getOrderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Pickup';
      case OrderType.dine_in:
        return 'Dine In';
    }
  }

  Widget buildOrderDetailsSheet(Map<String, dynamic> order) {
    final orderType = _getOrderType(order['order_type'] as String?);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(getOrderTypeIcon(orderType),
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
                      getOrderTypeLabel(orderType),
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
        ],
      ),
    );
  }

  Widget buildRefundsTab() {
    return FutureBuilder<int?>(
      future: _getCurrentStudentId(),
      builder: (context, studentSnapshot) {
        if (!studentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final studentId = studentSnapshot.data!;
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _transactionService
              .getOrderHistory(studentId)
              .then((orders) async {
            final cancelledOrders =
                orders.where((order) => order['status'] == 'cancelled');

            List<Map<String, dynamic>> allRefunds = [];
            for (final order in cancelledOrders) {
              final refunds =
                  await _refundService.getRefundsByTransactionId(order['id']);
              allRefunds.addAll(refunds);
            }

            return allRefunds;
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final refunds = snapshot.data ?? [];

            if (refunds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No refunds to show',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: refunds.length,
              itemBuilder: (context, index) {
                final refund = refunds[index];
                return Card(
                  child: Dismissible(
                    key: Key(refund['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text('Remove this refund record?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      try {
                        await _refundService.deleteRefund(refund['id']);
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refund record removed'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to remove record: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: ListTile(
                      title: Text('Order #${refund['transaction_id']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d, y h:mm a')
                                .format(DateTime.parse(refund['created_at'])),
                          ),
                          Text(
                            refund['reason'] ?? 'No reason provided',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: _buildRefundStatusChip(refund['status']),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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

  bool _isOrderCompleted(Map<String, dynamic> order) {
    return order['status']?.toLowerCase() == 'completed';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
