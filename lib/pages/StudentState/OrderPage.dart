import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show Icon, Widget;
import 'package:intl/intl.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/services/menu_service.dart';
import 'package:kantin/utils/order_id_formatter.dart';
import 'package:kantin/utils/price_formatter.dart';
import 'package:kantin/widgets/enhanced_order_card.dart';
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
import 'package:kantin/widgets/review_history_tab.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:kantin/utils/time_formatter.dart';

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

  String _currentSortField =
      'created_at_timestamp'; // Changed from 'created_at'
  bool _sortAscending = false; // Keep false for descending (latest first)

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
    try {
      _orderSubscription = _supabase
          .from('transactions')
          .stream(primaryKey: ['id'])
          .eq('student_id', widget.studentId)
          .order('created_at')
          .listen((data) {
            if (mounted) {
              _handleOrdersUpdate(
                List<Map<String, dynamic>>.from(data),
              );
            }
          });
    } catch (e) {
      print('Error setting up order subscription: $e');
    }
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
        original_price,
        discounted_price,
        applied_discount_percentage,
        menu:menu_id (
          id,
          food_name,      
          photo,     
          reviews!menu_id (*),
          stall:stalls (
            id,
            nama_stalls,
            image_url,
            Banner_img,
            deskripsi
          )
        ),
        addon_name,        
        addon_price,       
        addon_quantity,    
        addon_subtotal     
      )
    ''')
          .eq('student_id', widget.studentId)
          .order('created_at', ascending: false);
      // Debug log for add-ons
      print('\n=== Debug: First order add-ons ===');
      if (allOrders.isNotEmpty && allOrders[0]['items'].isNotEmpty) {
        print('First item addons: ${allOrders[0]['items'][0]['addons']}');
      }
      print('================================\n');

      // Apply virtual IDs to orders
      final ordersWithVirtualIds =
          OrderListExtension(allOrders).withVirtualIds();

      if (mounted) {
        setState(() {
          _activeOrders = ordersWithVirtualIds
              .where((order) => !['completed', 'cancelled']
                  .contains(order['status']?.toString().toLowerCase() ?? ''))
              .toList();

          _orderHistory = ordersWithVirtualIds
              .where((order) => ['completed', 'cancelled']
                  .contains(order['status']?.toString().toLowerCase() ?? ''))
              .toList();

          _error = null;
        });
      }
    } catch (e, stack) {
      _logger.error('Error loading orders', e, stack);
      _handleError(e);
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
            const material.Icon(Icons.error_outline, color: Colors.white),
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
    final String? menuPhoto = menuItem['menu']?['photo']; // Get the photo URL

    if (menuId == null || stallId == null) {
      _logger.error('Missing required data for rating');
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
        menuPhoto: menuPhoto, // Pass the photo URL
        onRatingSubmitted: () {
          _loadOrders();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRefundDetails(int transactionId) async {
    try {
      final refunds = await _refundService
          .getRefundsByTransactionId(transactionId); // Convert string ID to int
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
                    icon: const material.Icon(Icons.close),
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
                          child: const material.Icon(
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

  material.Widget _buildRefundStatusChip(String status) {
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
  material.Widget build(BuildContext context) {
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
              const material.Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
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
              icon: const material.Icon(Icons.sort),
              onPressed: _showSortOptions,
            ),
            IconButton(
              icon: const material.Icon(Icons.refresh),
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
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                  _buildSortOptionTile(
                    context,
                    setState,
                    'Date',
                    'created_at',
                    Icons.calendar_today,
                    subtitle: 'Sort by order date',
                  ),
                  _buildSortOptionTile(
                    context,
                    setState,
                    'Amount',
                    'total_amount',
                    Icons.attach_money,
                    subtitle: 'Sort by order total',
                  ),
                  _buildSortOptionTile(
                    context,
                    setState,
                    'Status',
                    'status',
                    Icons.info_outline,
                    subtitle: 'Sort by order status',
                  ),
                  _buildSortOptionTile(
                    context,
                    setState,
                    'Order Type',
                    'order_type',
                    Icons.local_shipping,
                    subtitle: 'Sort by delivery method',
                  ),
                  _buildSortOptionTile(
                    context,
                    setState,
                    'Items Count',
                    'items_count',
                    Icons.shopping_basket,
                    subtitle: 'Sort by number of items',
                  ),
                  // Add a reset option
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Reset Sort'),
                    subtitle: const Text('Return to default sorting'),
                    onTap: () {
                      setState(() {
                        _currentSortField = 'created_at_timestamp';
                        _sortAscending = false; // Latest first
                      });
                      _sortOrders();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptionTile(
    BuildContext context,
    StateSetter setState,
    String label,
    String field,
    IconData icon, {
    String? subtitle,
  }) {
    final bool isSelected = _currentSortField == field;
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? selectedColor : null,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? selectedColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? selectedColor.withOpacity(0.7) : null,
              ),
            )
          : null,
      trailing: isSelected
          ? Container(
              decoration: BoxDecoration(
                color: selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: selectedColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortAscending ? 'Asc' : 'Desc',
                    style: TextStyle(
                      color: selectedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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

        // Special handling for different fields
        switch (_currentSortField) {
          case 'created_at':
          case 'created_at_timestamp':
            // Convert to timestamps for consistent comparison
            final timestampA = valueA is int
                ? valueA
                : DateTime.parse(a['created_at']).millisecondsSinceEpoch;
            final timestampB = valueB is int
                ? valueB
                : DateTime.parse(b['created_at']).millisecondsSinceEpoch;
            // Always sort timestamps in descending order (latest first)
            return timestampB.compareTo(timestampA);
          // ...rest of the cases remain the same...
        }

        // Handle null values
        if (valueA == null && valueB == null) return 0;
        if (valueA == null) return _sortAscending ? -1 : 1;
        if (valueB == null) return _sortAscending ? 1 : -1;

        int comparison;
        if (valueA is num) {
          comparison = valueA.compareTo(valueB);
        } else {
          comparison = valueA.toString().compareTo(valueB.toString());
        }

        return _sortAscending ? comparison : -comparison;
      };

      _activeOrders.sort(comparator);
      _orderHistory.sort(comparator);
    });

    // Show sort confirmation
    if (mounted) {
      final String fieldName =
          _currentSortField.replaceAll('_', ' ').toLowerCase();
      final String direction = _sortAscending ? 'ascending' : 'descending';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('Sorted by $fieldName ($direction)'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Reset',
            onPressed: () {
              setState(() {
                _currentSortField = 'created_at';
                _sortAscending = false;
                _sortOrders();
              });
            },
          ),
        ),
      );
    }
  }

  material.Widget _buildErrorView() {
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
              child: const material.Icon(Icons.refresh),
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

  material.Widget _buildActiveOrders() {
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            material.Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
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
            material.Icon(Icons.receipt_long_outlined,
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

  material.Widget _buildOrderHistory() {
    if (_orderHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            material.Icon(Icons.history, size: 64, color: Colors.grey[400]),
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
        itemBuilder: (context, index) {
          final order = _orderHistory[index];
          return FutureBuilder<Map<String, dynamic>>(
            future: _transactionService.fetchOrderTrackingDetails(order['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorItem('Order #${order['id']}', 1);
              }

              // Safely handle null or empty data
              final data = snapshot.data;
              if (data == null || !data.containsKey('items')) {
                return _buildErrorItem(
                  'Order #${order['id']}',
                  1,
                  message: 'No order details available',
                );
              }

              final items =
                  List<Map<String, dynamic>>.from(data['items'] ?? []);
              if (items.isEmpty) {
                return _buildErrorItem(
                  'Order #${order['id']}',
                  1,
                  message: 'No items in this order',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderCard(order, false),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Order Items',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...items.map((item) => _buildOrderItem(item)),
                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }

  material.Widget _buildOrderItem(Map<String, dynamic> item) {
    // Debug logging - combine into single argument
    _logger.debug('Order item data: ${{
      'original_price': item['original_price'],
      'discounted_price': item['discounted_price'],
      'applied_discount_percentage': item['applied_discount_percentage'],
      'quantity': item['quantity'],
      'menu_data': item['menu']
    }}');

    // Extract static values from transaction_details
    final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 0.0;
    final discountedPrice =
        (item['discounted_price'] as num?)?.toDouble() ?? originalPrice;
    final quantity = item['quantity'] as int? ?? 1;
    final discountPercentage =
        (item['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0;
    final notes = item['notes'] as String?;
    final menuItem = item['menu'] ?? {};
    final menuName = menuItem['food_name'] ?? 'Unknown Item';
    final menuPhoto = menuItem['photo'] as String?;

    // Calculate totals using static values
    final subtotal = discountedPrice * quantity;
    final originalSubtotal = originalPrice * quantity;
    final hasDiscount = discountPercentage > 0;
    final savings = originalSubtotal - subtotal;

    // Validate calculations
    _logger.debug('Price calculations: ${{
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'originalSubtotal': originalSubtotal,
      'savings': savings,
      'hasDiscount': hasDiscount
    }}');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (menuPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  menuPhoto,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (notes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: $notes',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${quantity}x',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_offer_outlined,
                                  size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '-${discountPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasDiscount)
                  Text(
                    PriceFormatter.format(originalSubtotal),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                Text(
                  PriceFormatter.format(subtotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasDiscount ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
                if (savings > 0)
                  Text(
                    'Save ${PriceFormatter.format(savings)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
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

  material.Widget _buildQuantityAndDiscountBadges(
      int quantity, Map<String, dynamic> priceData) {
    return Wrap(
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${quantity}x',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (priceData['hasDiscount'])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '-${priceData['discountPercentage'].round()}%',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  material.Widget _buildAddonsSection(List<dynamic> addons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Add-ons',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        ...addons.map((addon) {
          final name = addon['addon']?['addon_name'] ?? 'Unknown Add-on';
          final quantity = addon['quantity'] ?? 1;
          final subtotal = (addon['subtotal'] as num?)?.toDouble() ?? 0.0;

          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$name (${quantity}x)',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  PriceFormatter.format(subtotal),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  material.Widget _buildPriceDisplay(Map<String, dynamic> priceData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (priceData['hasDiscount'])
          Text(
            PriceFormatter.format(priceData['originalTotal']),
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        Text(
          PriceFormatter.format(priceData['subtotal']),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color:
                priceData['hasDiscount'] ? Colors.red.shade700 : Colors.black87,
          ),
        ),
        if (priceData['savings'] > 0)
          Text(
            'Save ${PriceFormatter.format(priceData['savings'])}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  material.Widget _buildOrderCard(Map<String, dynamic> order, bool isActive) {
    final DateTime orderDate = DateTime.parse(order['created_at']);
    final String status = order['status'];
    final List<dynamic> items = order['items'] ?? [];
    final orderType = _getOrderType(order['order_type'] as String?);

    // Remove SlideTransition and use a simpler animation
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                  const Divider(height: 24),
                  _buildOrderTotal(order),
                  if (isActive) _buildActionButtons(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  material.Widget _buildOrderHeader(Map<String, dynamic> order, String status) {
    // Get the stall info from the first item's menu
    final stall = order['items']?[0]?['menu']?['stall'] ?? {};
    final String stallName = stall['nama_stalls'] ?? 'Restaurant Name';
    final String? imageUrl = stall['image_url'];

    // Use virtual_id instead of id for display
    final String orderId = OrderIdFormatter.format(order['virtual_id'] ?? 0);

    // Update the time formatting
    final orderDate = DateTime.parse(order['created_at']);
    TimeFormatter.logTimeConversion(orderDate, 'Order Header');

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
                      child: const material.Icon(Icons.restaurant,
                          color: Colors.grey),
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
                    child: const material.Icon(Icons.restaurant,
                        color: Colors.grey),
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
                  'Order $orderId', // Use formatted virtual ID
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  TimeFormatter.formatDateTime(orderDate),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          _buildStatusChip(status),
        ],
      ),
    );
  }

  material.Widget _buildOrderInfo(
      DateTime orderDate, OrderType orderType, Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ordered on ${TimeFormatter.formatDateTime(orderDate.toLocal())}', // Updated to use TimeFormatter
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            material.Icon(
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

  material.Widget _buildOrderTotal(Map<String, dynamic> order) {
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

  material.Widget _buildActionButtons(Map<String, dynamic> order) {
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

  material.Widget _buildStatusChip(String status) {
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
          material.Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  material.Widget _buildOrderTimeline(String status) {
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
    // Remove reference to undefined order variable
    final statusTime = DateTime.now(); // Use current time as fallback

    TimeFormatter.logTimeConversion(statusTime, 'Status Timeline');

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

  material.Widget _buildItemsList(
      List<dynamic> items, Map<String, dynamic> order) {
    if (items.isEmpty) {
      _logger.warn('No items found for order ${order['id']}');
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            const Text('No items in this order'),
          ],
        ),
      );
    }

    // Safe type conversion of items
    final safeItems = items.whereType<Map<String, dynamic>>().toList();
    if (safeItems.isEmpty) {
      _logger.error('Invalid item format in order ${order['id']}');
      return _buildErrorItem(
        'Order #${order['id']}',
        1,
        message: 'Invalid order data format',
      );
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
        ...safeItems.map((item) {
          _logger.debug('Processing item: $item');
          return EnhancedOrderCard(
            item: {
              ...item,
              'addons': item['addons'] ?? [],
            },
            order: order,
            priceData: {
              'hasDiscount': item['applied_discount_percentage'] != null &&
                  (item['applied_discount_percentage'] as num) > 0,
              'originalPrice':
                  (item['original_price'] as num?)?.toDouble() ?? 0.0,
              'discountedPrice':
                  (item['discounted_price'] as num?)?.toDouble() ??
                      (item['original_price'] as num?)?.toDouble() ??
                      0.0,
              'discountPercentage':
                  (item['applied_discount_percentage'] as num?)?.toDouble() ??
                      0.0,
              'quantity': item['quantity'] as int? ?? 1,
              'subtotal': ((item['discounted_price'] as num?)?.toDouble() ??
                      (item['original_price'] as num?)?.toDouble() ??
                      0.0) *
                  (item['quantity'] as int? ?? 1),
            },
            ratingData: {'average': 0.0, 'count': 0},
            isCompleted: _isOrderCompleted(order),
            onRatePressed: () => _refreshOrders(),
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
  material.Widget _buildLoadingItem(String menuName, int quantity) {
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
  material.Widget _buildErrorItem(String orderId, int quantity,
      {String? message}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (message != null)
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Main item card widget
  material.Widget _buildItemCard({
    required String menuName,
    required int quantity,
    required Map<String, dynamic> ratingData,
    required Map<String, dynamic> priceData,
    required Map<String, dynamic> order,
    required Map<String, dynamic> item,
  }) {
    return EnhancedOrderCard(
      item: item,
      order: order,
      priceData: priceData,
      ratingData: ratingData,
      isCompleted: _isOrderCompleted(order),
      onRatePressed: () {
        final menuData = {
          'id': item['menu']?['id'],
          'menu_name': menuName,
          'stall': item['menu']?['stall'],
          'transaction_id': order['id'],
        };
        _showRatingDialog(menuData);
      },
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

  material.Widget buildOrderDetailsSheet(Map<String, dynamic> order) {
    final orderType = _getOrderType(order['order_type'] as String?);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                material.Icon(getOrderTypeIcon(orderType),
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

  material.Widget buildRefundsTab() {
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
                    const material.Icon(Icons.error_outline,
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
                    material.Icon(Icons.receipt_long_outlined,
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
                      child: const material.Icon(Icons.delete,
                          color: Colors.white),
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

  material.Widget _buildRatingButton(
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
          icon: material.Icon(
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

  // Add this method to handle order taps
  void _handleOrderTap(Map<String, dynamic> order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsSheet(
          order: order,
          onRefresh: () {
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  material.Widget _buildDeliveryEstimate(Map<String, dynamic> order) {
    final estimatedTime = order['estimated_delivery_time'] != null
        ? DateTime.parse(order['estimated_delivery_time'])
        : null;

    TimeFormatter.logTimeConversion(estimatedTime, 'Delivery Estimate');

    return Text(
      TimeFormatter.formatDeliveryEstimate(estimatedTime),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  // material.Widget _buildOrderItem(Map<String, dynamic> item) {
  //   // Extract values from transaction_details
  //   final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 0.0;
  //   final discountedPrice =
  //       (item['discounted_price'] as num?)?.toDouble() ?? originalPrice;
  //   final quantity = item['quantity'] as int? ?? 1;
  //   final discountPercentage =
  //       (item['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0;
  //   final notes = item['notes'] as String?;
  //   final menuItem = item['menu'] ?? {};
  //   final menuName = menuItem['food_name'] ?? 'Unknown Item';
  //   final menuPhoto = menuItem['photo'] as String?;

  //   final hasDiscount = discountPercentage > 0;
  //   final savings = (originalPrice - discountedPrice) * quantity;
  //   final subtotal = discountedPrice * quantity;

  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Row(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           if (menuPhoto != null)
  //             ClipRRect(
  //               borderRadius: BorderRadius.circular(8),
  //               child: Image.network(
  //                 menuPhoto,
  //                 width: 60,
  //                 height: 60,
  //                 fit: BoxFit.cover,
  //                 errorBuilder: (_, __, ___) => Container(
  //                   width: 60,
  //                   height: 60,
  //                   color: Colors.grey[200],
  //                   child: const Icon(Icons.fastfood, color: Colors.grey),
  //                 ),
  //               ),
  //             ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   menuName,
  //                   style: const TextStyle(
  //                     fontWeight: FontWeight.bold,
  //                     fontSize: 16,
  //                   ),
  //                 ),
  //                 if (notes != null) ...[
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     'Note: $notes',
  //                     style: TextStyle(
  //                       color: Colors.grey[600],
  //                       fontSize: 12,
  //                       fontStyle: FontStyle.italic,
  //                     ),
  //                   ),
  //                 ],
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   children: [
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 8,
  //                         vertical: 4,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: Colors.blue.shade50,
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                       child: Text(
  //                         '${quantity}x',
  //                         style: TextStyle(
  //                           color: Colors.blue.shade700,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                     if (hasDiscount) ...[
  //                       const SizedBox(width: 8),
  //                       Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 8,
  //                           vertical: 4,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: Colors.red.shade50,
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                         child: Text(
  //                           '-${discountPercentage.round()}%',
  //                           style: TextStyle(
  //                             color: Colors.red.shade700,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.end,
  //             children: [
  //               if (hasDiscount)
  //                 Text(
  //                   PriceFormatter.format(originalPrice * quantity),
  //                   style: TextStyle(
  //                     decoration: TextDecoration.lineThrough,
  //                     color: Colors.grey[600],
  //                     fontSize: 13,
  //                   ),
  //                 ),
  //               Text(
  //                 PriceFormatter.format(subtotal),
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 16,
  //                   color: hasDiscount ? Colors.red.shade700 : Colors.black87,
  //                 ),
  //               ),
  //               if (savings > 0)
  //                 Text(
  //                   'Save ${PriceFormatter.format(savings)}',
  //                   style: TextStyle(
  //                     color: Colors.green.shade700,
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
