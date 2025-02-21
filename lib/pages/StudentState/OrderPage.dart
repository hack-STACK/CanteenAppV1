import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/Services/menu_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/widgets/order_details_sheet.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/widgets/cancel_order_dialog.dart';
import 'package:kantin/widgets/loading_overlay.dart';
import 'package:kantin/widgets/rate_menu_dialog.dart';
import 'package:kantin/Services/Database/refund_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/Services/rating_service.dart';
import 'package:kantin/widgets/rating_indicator.dart';
import 'package:kantin/widgets/review_history_tab.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

// Add this extension outside the class at the top of the file
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

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

  late AnimationController _refreshIconController;
  late AnimationController _slideController;

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

    _refreshIconController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Start the slide animation when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
    });
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
    _refreshIconController.dispose();
    _slideController.dispose();
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

      // Updated query to use 'reviews' instead of 'ratings'
      final allOrders = await _supabase
          .from('transactions')
          .select('''
            *,
            items:transaction_details ( 
              id,
              quantity,
              unit_price,
              subtotal,
              notes,
              menu:menu (
                id,
                food_name,
                price,
                photo,
                reviews!menu_id (*), 
                stall:stalls (
                  id,
                  nama_stalls,
                  image_url,
                  Banner_img,
                  deskripsi
                )
              )
            )
          ''')
          .eq('student_id', widget.studentId)
          .order('created_at', ascending: false);

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
    final int? stallId = menuItem['stall']?['id'];
    final int? transactionId = menuItem['transaction_id'];

    if (menuId == null || stallId == null) {
      _logger.error(
          'Missing required data for rating. MenuId: $menuId, StallId: $stallId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot rate this item: Missing required information'),
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
        stallId: stallId,
        transactionId: transactionId ?? 0,
        onRatingSubmitted: () {
          // Refresh the order list to show updated ratings
          _loadOrders();
          Navigator.pop(context);
        },
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
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveOrders(),
                  _buildOrderHistory(),
                  ReviewHistoryTab(
                    studentId:
                        widget.studentId, // Use widget.studentId directly here
                  ),
                ],
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
      comparator(Map<String, dynamic> a, Map<String, dynamic> b) {
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
      }

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
          Lottie.asset(
            'assets/animations/error.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 24),
          AnimatedTextKit(
            animatedTexts: [
              FadeAnimatedText(
                'Oops! Something went wrong',
                textStyle: Theme.of(context).textTheme.headlineSmall,
                duration: const Duration(seconds: 2),
              ),
            ],
            totalRepeatCount: 1,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'We\'re having trouble loading your orders',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _refreshIconController.forward(from: 0);
              _refreshOrders();
            },
            icon: RotationTransition(
              turns:
                  Tween(begin: 0.0, end: 1.0).animate(_refreshIconController),
              child: const Icon(Icons.refresh),
            ),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
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

    return Hero(
      tag: 'order_${order['id']}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                _buildOrderHeader(order, status),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfo(orderDate, orderType, order),
                      const SizedBox(height: 16),
                      _buildOrderTimeline(status),
                      const SizedBox(height: 16),
                      _buildItemsList(items, order),
                      if (items.isNotEmpty) const Divider(height: 24),
                      _buildOrderSummary(order),
                      if (isActive) _buildActionButtons(order),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'pending' => Colors.orange,
      'confirmed' => Colors.blue,
      'cooking' => Colors.amber,
      'ready' => Colors.green,
      'delivering' => Colors.green,
      'completed' => Colors.teal,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    final subtotal = order['total_amount'] as num;
    final deliveryFee = order['delivery_fee'] as num? ?? 0;
    final discount = order['discount_amount'] as num? ?? 0;
    final total = subtotal + deliveryFee - discount;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSummaryRow('Subtotal', subtotal),
            if (deliveryFee > 0) ...[
              const SizedBox(height: 4),
              _buildSummaryRow('Delivery Fee', deliveryFee),
            ],
            if (discount > 0) ...[
              const SizedBox(height: 4),
              _buildSummaryRow(
                'Discount',
                -discount,
                valueColor: Colors.green,
              ),
            ],
            const Divider(height: 16),
            _buildSummaryRow(
              'Total',
              total,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    num amount, {
    TextStyle? style,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          NumberFormat.currency(
            locale: 'id',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(amount),
          style: style?.copyWith(color: valueColor) ??
              TextStyle(color: valueColor),
        ),
      ],
    );
  }

  Widget _buildOrderHeader(Map<String, dynamic> order, String status) {
    // Get the stall info from the first item's menu
    final stall = order['items']?[0]?['menu']?['stall'] ?? {};
    final String stallName = stall['nama_stalls'] ?? 'Restaurant Name';
    final String? imageUrl = stall['image_url'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stallName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Order #${order['id']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(status),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(
      DateTime orderDate, OrderType orderType, Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ordered on ${DateFormat('MMM d, y h:mm a').format(orderDate)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _buildOrderTotal(Map<String, dynamic> order) {
    return Row(
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
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showOrderDetails(order),
            child: const Text('Track Order'),
          ),
        ),
      ],
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
          final menuData = item['menu'];
          final menuId = menuData?['id'] ?? item['menu_id'];
          final quantity = item['quantity'] ?? 1;
          final menuName = menuData?['food_name'] ?? 'Unknown Item';

          if (menuId == null) {
            _logger.error("Missing menu ID for item in order ${order['id']}");
            return const SizedBox.shrink();
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: _getItemDetails(menuId, menuData, quantity),
            builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
              if (snapshot.hasError) {
                _logger.error("Error loading item details: ${snapshot.error}");
                return _buildErrorItem(menuName, quantity);
              }

              if (!snapshot.hasData) {
                return _buildLoadingItem(menuName, quantity);
              }

              final data = snapshot.data!;
              return _buildItemCard(
                menuName: menuName,
                quantity: quantity,
                ratingData: data['rating'] as Map<String, dynamic>,
                priceData: data['price'] as Map<String, dynamic>,
                order: order,
                item: item,
              );
            },
          );
        }).toList(),
      ],
    );
  }

// Combine rating and price calculations into one Future
  Future<Map<String, dynamic>> _getItemDetails(
    dynamic menuId,
    Map<String, dynamic>? menuData,
    int quantity,
  ) async {
    final ratingFuture = RatingService().getMenuRatingSummary(menuId);
    final priceFuture = _calculatePriceDetails(menuId, menuData, quantity);

    final results = await Future.wait([ratingFuture, priceFuture]);

    return {
      'rating': results[0],
      'price': results[1],
    };
  }

  Future<Map<String, dynamic>> _calculatePriceDetails(
    dynamic menuId,
    Map<String, dynamic>? menuData,
    int quantity,
  ) async {
    try {
      if (menuData == null) {
        return {
          'originalPrice': 0.0,
          'discountedPrice': 0.0,
          'savings': 0.0,
          'hasDiscount': false,
        };
      }

      final originalPrice = (menuData['price'] as num).toDouble();
      final discountedPrice = await MenuService().getDiscountedPrice(
        menuId,
        originalPrice,
      );

      final totalOriginalPrice = originalPrice * quantity;
      final totalDiscountedPrice = discountedPrice * quantity;
      final savings = totalOriginalPrice - totalDiscountedPrice;

      return {
        'originalPrice': totalOriginalPrice,
        'discountedPrice': totalDiscountedPrice,
        'savings': savings,
        'hasDiscount': savings > 0,
      };
    } catch (e) {
      _logger.error('Error calculating price details: $e');
      return {
        'originalPrice': 0.0,
        'discountedPrice': 0.0,
        'savings': 0.0,
        'hasDiscount': false,
      };
    }
  }

// Widget for loading state
  Widget _buildLoadingItem(String menuName, int quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${quantity}x $menuName',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(
            width: 80,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget for error state
  Widget _buildErrorItem(String menuName, int quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${quantity}x $menuName',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Icon(Icons.error_outline, color: Colors.red[700], size: 16),
        ],
      ),
    );
  }

// Main item card widget
  Widget _buildItemCard({
    required String menuName,
    required int quantity,
    required Map<String, dynamic> ratingData,
    required Map<String, dynamic> priceData,
    required Map<String, dynamic> order,
    required Map<String, dynamic> item,
  }) {
    final rating = ratingData['average'] ?? 0.0;
    final ratingCount = ratingData['count'] ?? 0;
    final hasDiscount = priceData['hasDiscount'] as bool;
    final savings = priceData['savings'] as double;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quantity}x $menuName',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (ratingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          RatingIndicator(
                            rating: rating,
                            ratingCount: ratingCount,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($ratingCount)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Save: ${NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(savings)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    NumberFormat.currency(
                      locale: 'id',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(priceData['originalPrice']),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                Text(
                  NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(priceData['discountedPrice']),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hasDiscount ? Colors.red[700] : null,
                  ),
                ),
                if (_isOrderCompleted(order))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildRatingButton(item, order),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

      // Fix the query to select the entire students record
      final studentData = await _supabase
          .from('students')
          .select() // Remove 'students.id' and use simple select()
          .eq('id_user', userData.id!)
          .single();

      _logger.debug('Found student data: $studentData');
      return studentData['id'] as int;
    } catch (e) {
      _logger.error('Error getting current student ID', e);
      return widget.studentId; // Fallback to the studentId passed to the widget
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
    return switch (type) {
      OrderType.delivery => 'Delivery',
      OrderType.pickup => 'Pickup',
      OrderType.dine_in => 'Dine In',
    };
  }

  IconData _getOrderTypeIcon(OrderType type) {
    return switch (type) {
      OrderType.delivery => Icons.delivery_dining,
      OrderType.pickup => Icons.store_mall_directory,
      OrderType.dine_in => Icons.restaurant,
    };
  }

  bool _isOrderCompleted(Map<String, dynamic> order) {
    return order['status']?.toLowerCase() == 'completed';
  }

  Widget _buildRatingButton(
      Map<String, dynamic> item, Map<String, dynamic> order) {
    final int menuId = item['menu']?['id'] ?? -1;
    if (menuId == -1) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: RatingService().hasUserRatedMenu(menuId, order['id']),
      builder: (context, hasRatedSnapshot) {
        if (hasRatedSnapshot.hasError) {
          _logger.error('Rating check error:', hasRatedSnapshot.error);
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
                    'menu_name': item['menu']?['food_name'] ?? 'Unknown Item',
                    'stall': item['menu']?['stall'],
                    'transaction_id': order['id'],
                  };
                  _showRatingDialog(menuData);
                },
          tooltip: hasRated ? 'Already rated' : 'Rate this item',
          iconSize: 20,
        );
      },
    );
  }
}
