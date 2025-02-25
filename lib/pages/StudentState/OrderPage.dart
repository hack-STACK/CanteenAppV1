import 'dart:async';
import 'dart:math' as math;

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
import 'package:kantin/widgets/rating_indicator.dart';
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
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

// Add this extension outside the class at the top of the file
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

// Create a global logger for the static methods
final _globalLogger = Logger('OrderPage');

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
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredActiveOrders = [];
  List<Map<String, dynamic>> _filteredOrderHistory = [];

  // Pagination variables
  int _activeOrdersPage = 1;
  int _historyOrdersPage = 1;
  final int _ordersPerPage = 5;
  bool _hasMoreActiveOrders = true;
  bool _hasMoreHistoryOrders = true;
  bool _isLoadingMoreActive = false;
  bool _isLoadingMoreHistory = false;

  // Filter variables
  String _statusFilter = 'All';
  String _timeFilter = 'All';
  String _orderTypeFilter = 'All';

  String _currentSortField =
      'created_at_timestamp'; // Changed from 'created_at'
  bool _sortAscending = false; // Keep false for descending (latest first)

  late AnimationController _refreshIconController;
  late AnimationController _slideController;
  late AnimationController _fabAnimationController;

  // Scroll controllers for pagination
  final ScrollController _activeOrdersScrollController = ScrollController();
  final ScrollController _orderHistoryScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize loading state
    setState(() => _isLoading = true);

    // Setup subscription which now will trigger a full reload on update
    _setupOrderSubscription();

    // Rest of your initState code...
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

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Start the slide animation when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slideController.forward();
      _fabAnimationController.forward();
    });

    // Setup scroll listeners for pagination
    _activeOrdersScrollController.addListener(_scrollListenerActiveOrders);
    _orderHistoryScrollController.addListener(_scrollListenerOrderHistory);

    // Listen for tab changes to update search and filters
    _tabController.addListener(() {
      if (_isSearching) {
        _filterOrders();
      }
    });
  }

  void _scrollListenerActiveOrders() {
    if (_activeOrdersScrollController.position.pixels >=
            _activeOrdersScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreActive &&
        _hasMoreActiveOrders) {
      _loadMoreActiveOrders();
    }
  }

  void _scrollListenerOrderHistory() {
    if (_orderHistoryScrollController.position.pixels >=
            _orderHistoryScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreHistory &&
        _hasMoreHistoryOrders) {
      _loadMoreHistoryOrders();
    }
  }

  Future<void> _loadMoreActiveOrders() async {
    if (!_hasMoreActiveOrders || _isLoadingMoreActive) return;

    setState(() {
      _isLoadingMoreActive = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _activeOrdersPage++;
      _isLoadingMoreActive = false;

      // Check if we've loaded all orders
      if (_activeOrdersPage * _ordersPerPage >= _activeOrders.length) {
        _hasMoreActiveOrders = false;
      }

      // Apply filters if searching
      if (_isSearching) {
        _filterOrders();
      }
    });
  }

  Future<void> _loadMoreHistoryOrders() async {
    if (!_hasMoreHistoryOrders || _isLoadingMoreHistory) return;

    setState(() {
      _isLoadingMoreHistory = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _historyOrdersPage++;
      _isLoadingMoreHistory = false;

      // Check if we've loaded all orders
      if (_historyOrdersPage * _ordersPerPage >= _orderHistory.length) {
        _hasMoreHistoryOrders = false;
      }

      // Apply filters if searching
      if (_isSearching) {
        _filterOrders();
      }
    });
  }

  void _resetPagination() {
    setState(() {
      _activeOrdersPage = 1;
      _historyOrdersPage = 1;
      _hasMoreActiveOrders = true;
      _hasMoreHistoryOrders = true;
      _isLoadingMoreActive = false;
      _isLoadingMoreHistory = false;
    });
  }

  void _setupOrderSubscription() {
    try {
      _orderSubscription?.cancel(); // Cancel existing subscription if any

      _orderSubscription =
          _transactionService.subscribeToOrders(widget.studentId).listen(
        (orders) {
          // Instead of manually setting state from the orders payload,
          // re-fetch the orders to ensure complete and consistent data.
          _loadOrders();
        },
        onError: (error) {
          _logger.error('Order subscription error:', error);
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isConnected = false;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      _logger.error('Error setting up order subscription:', e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isConnected = false;
          _isLoading = false;
        });
      }
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

        // Reset pagination when data updates
        _resetPagination();

        // Apply filters if searching
        if (_isSearching) {
          _filterOrders();
        }
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
    _fabAnimationController.dispose();
    _searchController.dispose();
    _activeOrdersScrollController.removeListener(_scrollListenerActiveOrders);
    _orderHistoryScrollController.removeListener(_scrollListenerOrderHistory);
    _activeOrdersScrollController.dispose();
    _orderHistoryScrollController.dispose();
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

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) {
      _setLoading(true);
    }
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

          // Reset pagination when loading new data
          _resetPagination();

          // Apply filters if searching
          if (_isSearching) {
            _filterOrders();
          }
        });
      }
    } catch (e, stack) {
      _logger.error('Error loading orders', e, stack);
      _handleError(e);
    } finally {
      if (showLoading) {
        _setLoading(false);
      }
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
    // Do not set global loading here to avoid blinking; refresh silently.
    _orderSubscription?.cancel();
    _setupOrderSubscription();
    try {
      await _loadOrders(showLoading: false);
    } catch (e) {
      _logger.error('Error refreshing orders:', e);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isConnected = false;
        });
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
      // Using fully qualified type to avoid ambiguity
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
    _logger.info('Show rating dialog triggered with: $menuItem');

    // Extract required data properly
    final int? menuId = menuItem['id'] ?? menuItem['menu']?['id'];
    final int? stallId =
        menuItem['stall']?['id'] ?? menuItem['menu']?['stall']?['id'];
    final int? transactionId = menuItem['transaction_id'];
    final String? menuName = menuItem['menu_name'] ??
        menuItem['menu']?['food_name'] ??
        'Unknown Item';
    final String? menuPhoto = menuItem['photo'] ?? menuItem['menu']?['photo'];

    _logger.info(
        'Rating info: menuId=$menuId, stallId=$stallId, transactionId=$transactionId');

    if (menuId == null || stallId == null) {
      _logger.error(
          'Missing required data for rating: menuId=$menuId, stallId=$stallId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot rate this item: Missing required information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // First check if the user has already rated this menu item
    RatingService()
        .hasUserRatedMenu(menuId, transactionId ?? 0)
        .then((hasRated) {
      if (hasRated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already rated this item'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // If not rated, show the rating dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => RateMenuDialog(
          menuName: menuName ?? 'Unknown Item',
          menuId: menuId,
          stallId: stallId,
          transactionId: transactionId ?? 0,
          menuPhoto: menuPhoto,
          onRatingSubmitted: () {
            _loadOrders();
            Navigator.pop(context);
          },
        ),
      );
    }).catchError((error) {
      _logger.error('Error checking rating status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking rating status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
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

  // Search and filter methods
  void _startSearch() {
    setState(() {
      _isSearching = true;
      _filterOrders();
    });
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _statusFilter = 'All';
      _timeFilter = 'All';
      _orderTypeFilter = 'All';
      _filteredActiveOrders = [];
      _filteredOrderHistory = [];
      _resetPagination();
    });
  }

  void _filterOrders() {
    final String searchTerm = _searchController.text.toLowerCase();

    // Filter active orders
    final filteredActive = _activeOrders.where((order) {
      // Search by order ID, stall name, or status
      bool matchesSearch = searchTerm.isEmpty ||
          order['virtual_id'].toString().contains(searchTerm) ||
          (order['items']?[0]?['menu']?['stall']?['nama_stalls'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchTerm) ||
          (order['status'] ?? '').toString().toLowerCase().contains(searchTerm);

      // Apply status filter
      bool matchesStatus = _statusFilter == 'All' ||
          order['status']?.toString().toLowerCase() ==
              _statusFilter.toLowerCase();

      // Apply time filter
      bool matchesTime = _timeFilter == 'All';
      if (!matchesTime) {
        final orderDate = DateTime.parse(order['created_at']);
        final now = DateTime.now();
        switch (_timeFilter) {
          case 'Today':
            matchesTime = orderDate.day == now.day &&
                orderDate.month == now.month &&
                orderDate.year == now.year;
            break;
          case 'This Week':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            matchesTime =
                orderDate.isAfter(weekStart.subtract(const Duration(days: 1)));
            break;
          case 'This Month':
            matchesTime =
                orderDate.month == now.month && orderDate.year == now.year;
            break;
        }
      }

      // Apply order type filter
      bool matchesType = _orderTypeFilter == 'All' ||
          order['order_type']?.toString().toLowerCase() ==
              _orderTypeFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesTime && matchesType;
    }).toList();

    // Filter order history
    final filteredHistory = _orderHistory.where((order) {
      bool matchesSearch = searchTerm.isEmpty ||
          order['virtual_id'].toString().contains(searchTerm) ||
          (order['items']?[0]?['menu']?['stall']?['nama_stalls'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchTerm) ||
          (order['status'] ?? '').toString().toLowerCase().contains(searchTerm);

      bool matchesStatus = _statusFilter == 'All' ||
          order['status']?.toString().toLowerCase() ==
              _statusFilter.toLowerCase();

      bool matchesTime = _timeFilter == 'All';
      if (!matchesTime) {
        final orderDate = DateTime.parse(order['created_at']);
        final now = DateTime.now();
        switch (_timeFilter) {
          case 'Today':
            matchesTime = orderDate.day == now.day &&
                orderDate.month == now.month &&
                orderDate.year == now.year;
            break;
          case 'This Week':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            matchesTime =
                orderDate.isAfter(weekStart.subtract(const Duration(days: 1)));
            break;
          case 'This Month':
            matchesTime =
                orderDate.month == now.month && orderDate.year == now.year;
            break;
        }
      }

      bool matchesType = _orderTypeFilter == 'All' ||
          order['order_type']?.toString().toLowerCase() ==
              _orderTypeFilter.toLowerCase();

      return matchesSearch && matchesStatus && matchesTime && matchesType;
    }).toList();

    setState(() {
      _filteredActiveOrders = filteredActive;
      _filteredOrderHistory = filteredHistory;

      // Reset pagination for filtered results
      _activeOrdersPage = 1;
      _historyOrdersPage = 1;
      _hasMoreActiveOrders = _filteredActiveOrders.length > _ordersPerPage;
      _hasMoreHistoryOrders = _filteredOrderHistory.length > _ordersPerPage;
    });
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Sort Orders By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          _buildSortOption(context, 'Order Date', 'created_at_timestamp'),
          _buildSortOption(context, 'Order Total', 'total_amount'),
          _buildSortOption(context, 'Order Status', 'status'),
        ],
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, String label, String field) {
    final bool isSelected = _currentSortField == field;

    return ListTile(
      leading: isSelected
          ? Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).primaryColor,
            )
          : null,
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
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
          // Fix the animation path
          Lottie.asset(
            'assets/animations/error.json',
            width: 200,
            height: 200,
            repeat: true,
            // Add error builder to handle missing animation
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red[300],
            ),
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

    // Wrap the ListView with its own RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshOrders,
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

    // Wrap the ListView with its own RefreshIndicator
    return RefreshIndicator(
      onRefresh: _refreshOrders,
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
                  ),
                  // ...items.map((item) => _buildOrderItem(item)),
                  // const SizedBox(height: 24),
                  // const Divider(thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    // Extract values from transaction_details
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

    final hasDiscount = discountPercentage > 0;
    final savings = (originalPrice - discountedPrice) * quantity;
    final subtotal = discountedPrice * quantity;

    // Add addon handling
    final addonName = item['addon_name'];
    final addonPrice = (item['addon_price'] as num?)?.toDouble();
    final addonQuantity = item['addon_quantity'] as int? ?? 1;
    final addonSubtotal = item['addon_subtotal'] as num?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Replace with safe image loading
                _buildSafeImage(
                  menuPhoto,
                  width: 60,
                  height: 60,
                  fallbackIcon: Icons.fastfood,
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
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '-${discountPercentage.round()}%',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
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
                        PriceFormatter.format(originalPrice * quantity),
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
                        color:
                            hasDiscount ? Colors.red.shade700 : Colors.black87,
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
            // Add addons section if exists
            if (addonName != null && addonPrice != null) ...[
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 72),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '+ $addonName (${addonQuantity}x)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      PriceFormatter.format(
                          (addonSubtotal ?? (addonPrice * addonQuantity))
                              .toDouble()),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show total with addons
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ${PriceFormatter.format(subtotal + (addonSubtotal?.toDouble() ?? 0.0))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

// Updated _buildOrderCard method with improved card layout:
  material.Widget _buildOrderCard(Map<String, dynamic> order, bool isActive) {
    final DateTime orderDate = DateTime.parse(order['created_at']);
    final String status = order['status'];
    final List<dynamic> items = order['items'] ?? [];
    final orderType = _getOrderType(order['order_type'] as String?);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with gradient and increased padding
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Order image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: _buildSafeImage(
                      order['items']?[0]?['menu']?['stall']?['image_url'],
                      width: 50,
                      height: 50,
                      fallbackIcon: Icons.restaurant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Order details text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order['items']?[0]?['menu']?['stall']
                                  ?['nama_stalls'] ??
                              'Restaurant Name',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order ${OrderIdFormatter.format(order['virtual_id'] ?? 0)}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TimeFormatter.formatDateTime(orderDate),
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            // Content area with enhanced spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderInfo(orderDate, orderType, order),
                  const SizedBox(height: 12),
                  _buildOrderTimeline(status),
                  const SizedBox(height: 12),
                  _buildItemsList(items, order),
                  const Divider(height: 24, thickness: 1),
                  _buildOrderTotal(order),
                  if (isActive) ...[
                    const SizedBox(height: 14),
                    _buildActionButtons(order),
                  ],
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
        // Limit the number of items displayed to prevent overflow
        // And wrap in a container with fixed height and scrolling
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              children: safeItems.map((item) {
                _logger.debug('Processing item: $item');

                // Create a proper menu data object for the rating functionality
                final menuData = {
                  'id': item['menu']?['id'],
                  'menu_name': item['menu']?['food_name'] ?? 'Unknown Item',
                  'stall': item['menu']?['stall'],
                  'transaction_id': order['id'],
                  'photo': item['menu']?['photo'],
                };

                return EnhancedOrderCard(
                  item: {
                    ...item,
                    'addons': item['addons'] ?? [],
                    'menuData': menuData, // Pass complete menu data
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
                  onRatePressed: () {
                    _logger.info(
                        'Rate button pressed for item: ${item['menu']?['food_name']}');
                    _showRatingDialog(menuData);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

// Combine rating and price calculations into one Future
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

// Widget for error state - Fix parameter type issues
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
          // tooltip: hasRated ? 'Already rated' : 'Rate this item',
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

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_isConnected) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          elevation: 0,
        ),
        body: _buildErrorView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search orders...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _cancelSearch,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  _filterOrders();
                },
                autofocus: true,
              )
            : const Text('My Orders'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
              tooltip: 'Search orders',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter orders',
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort orders',
            onPressed: () => _showSortMenu(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child:
              _isLoading ? const LinearProgressIndicator() : const SizedBox(),
        ),
      ),
      body: Column(
        children: [
          // Custom tab bar with indicators
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: material.Icon(Icons.receipt),
                  text: 'Active',
                ),
                Tab(
                  icon: material.Icon(Icons.history),
                  text: 'History',
                ),
                Tab(
                  icon: material.Icon(Icons.star),
                  text: 'Reviews',
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: LoadingOverlay(
              isLoading: _isLoading,
              child: RefreshIndicator(
                key: _refreshKey,
                onRefresh: _refreshOrders,
                color: Theme.of(context).primaryColor,
                backgroundColor: Colors.white,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Orders Tab with animations
                    AnimationLimiter(
                      child: _isSearching
                          ? _filteredActiveOrders.isEmpty
                              ? _buildEmptySearchState()
                              : _buildOrderList(
                                  _filteredActiveOrders,
                                  _activeOrdersScrollController,
                                  _hasMoreActiveOrders,
                                  true,
                                )
                          : _activeOrders.isEmpty
                              ? _buildEmptyActiveOrdersState()
                              : _buildOrderList(
                                  _activeOrders,
                                  _activeOrdersScrollController,
                                  _hasMoreActiveOrders,
                                  true,
                                ),
                    ),

                    // History Tab with animations
                    AnimationLimiter(
                      child: _isSearching
                          ? _filteredOrderHistory.isEmpty
                              ? _buildEmptySearchState()
                              : _buildOrderList(
                                  _filteredOrderHistory,
                                  _orderHistoryScrollController,
                                  _hasMoreHistoryOrders,
                                  false,
                                )
                          : _orderHistory.isEmpty
                              ? _buildEmptyHistoryState()
                              : _buildOrderList(
                                  _orderHistory,
                                  _orderHistoryScrollController,
                                  _hasMoreHistoryOrders,
                                  false,
                                ),
                    ),

                    // Reviews Tab - Keep existing implementation
                    AnimationLimiter(
                      child: ReviewHistoryTab(
                        studentId: widget.studentId,
                        onReviewTap: (review) {
                          _showReviewDetails(review);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        )),
        child: FloatingActionButton.extended(
          onPressed: () {
            _refreshIconController.forward(from: 0.0);
            _refreshOrders();
          },
          label: const Text('Refresh'),
          icon: RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_refreshIconController),
            child: const Icon(Icons.refresh),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 4,
        ),
      ),
    );
  }

  // Enhanced empty state builders
  Widget _buildEmptyActiveOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Fix the animation path - make sure this asset exists
          _buildSafeLottie(
            'assets/animations/empty_orders.json',
            width: 200,
            height: 200,
            fallbackIcon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            'No active orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your active orders will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/stalls');
            },
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Order Food'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No order history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed orders will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders match your search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your search or filters',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _cancelSearch,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  // Consolidated order list builder with animations
  Widget _buildOrderList(
    List<Map<String, dynamic>> orders,
    ScrollController scrollController,
    bool hasMoreItems,
    bool isActiveList,
  ) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: orders.length + (hasMoreItems ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= orders.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildOrderCard(orders[index], isActiveList),
            ),
          ),
        );
      },
    );
  }

  // Enhanced error state with better visuals - Renamed from _buildErrorView to _buildEnhancedErrorView
  material.Widget _buildEnhancedErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error ?? 'We\'re having trouble loading your orders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
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
              backgroundColor: Theme.of(context)
                  .primaryColor, // Changed from primary to backgroundColor
            ),
          ),
        ],
      ),
    );
  }

  // Filter dialog with improved UI
  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Orders',
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
                const Divider(),

                // Status Filter with better visualization
                const SizedBox(height: 16),
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'All',
                    'Pending',
                    'Confirmed',
                    'Cooking',
                    'Ready',
                    'Delivering',
                    'Completed',
                    'Cancelled'
                  ]
                      .map((status) => FilterChip(
                            selected: _statusFilter == status,
                            label: Text(status),
                            labelStyle: TextStyle(
                              color: _statusFilter == status
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: _statusFilter == status
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            selectedColor: Theme.of(context).primaryColor,
                            checkmarkColor: Colors.white,
                            backgroundColor: Colors.grey[200],
                            elevation: _statusFilter == status ? 2 : 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            onSelected: (selected) {
                              setModalState(() {
                                _statusFilter = selected ? status : 'All';
                              });
                              setState(() {
                                _statusFilter = selected ? status : 'All';
                              });
                              _filterOrders();
                            },
                          ))
                      .toList(),
                ),

                // Time Filter with better visualization
                const SizedBox(height: 24),
                Text(
                  'Time Period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Today', 'This Week', 'This Month']
                      .map((time) => ChoiceChip(
                            selected: _timeFilter == time,
                            label: Text(time),
                            labelStyle: TextStyle(
                              color: _timeFilter == time
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: _timeFilter == time
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            selectedColor: Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey[200],
                            elevation: _timeFilter == time ? 2 : 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            onSelected: (selected) {
                              setModalState(() {
                                _timeFilter = selected ? time : 'All';
                              });
                              setState(() {
                                _timeFilter = selected ? time : 'All';
                              });
                              _filterOrders();
                            },
                          ))
                      .toList(),
                ),

                // Order Type Filter with icons
                const SizedBox(height: 24),
                Text(
                  'Order Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    {'value': 'All', 'label': 'All Types', 'icon': Icons.list},
                    {
                      'value': 'Delivery',
                      'label': 'Delivery',
                      'icon': Icons.delivery_dining
                    },
                    {
                      'value': 'Pickup',
                      'label': 'Pickup',
                      'icon': Icons.store_mall_directory
                    },
                    {
                      'value': 'Dine_in',
                      'label': 'Dine In',
                      'icon': Icons.restaurant
                    }
                  ]
                      .map((type) => FilterChip(
                            avatar: CircleAvatar(
                              backgroundColor: _orderTypeFilter == type['value']
                                  ? Colors.white
                                  : Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                              child: Icon(
                                type['icon'] as IconData,
                                size: 16,
                                color: _orderTypeFilter == type['value']
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                            ),
                            selected: _orderTypeFilter == type['value'],
                            label: Text(type['label'] as String),
                            labelStyle: TextStyle(
                              color: _orderTypeFilter == type['value']
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: _orderTypeFilter == type['value']
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            selectedColor: Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey[200],
                            elevation:
                                _orderTypeFilter == type['value'] ? 2 : 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            onSelected: (selected) {
                              setModalState(() {
                                _orderTypeFilter =
                                    selected ? type['value'] as String : 'All';
                              });
                              setState(() {
                                _orderTypeFilter =
                                    selected ? type['value'] as String : 'All';
                              });
                              _filterOrders();
                            },
                          ))
                      .toList(),
                ),

                // Action buttons
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _statusFilter = 'All';
                            _timeFilter = 'All';
                            _orderTypeFilter = 'All';
                          });
                          setState(() {
                            _statusFilter = 'All';
                            _timeFilter = 'All';
                            _orderTypeFilter = 'All';
                            _filterOrders();
                          });
                        },
                        child: const Text('Reset Filters'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side:
                              BorderSide(color: Theme.of(context).primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _filterOrders();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .primaryColor, // Changed from primary to backgroundColor
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pretty review details modal
  void _showReviewDetails(Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar for draggable sheet
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Review header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Review',
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
                const Divider(),
                // Food photo if available
                if (review['menu']?['photo'] != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      review['menu']['photo'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Menu information
                Text(
                  review['menu']?['food_name'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.store, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      review['menu']?['stall']?['nama_stalls'] ??
                          'Unknown Stall',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Rating display with label
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Rating',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${(review['rating'] as num).toDouble()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              RatingIndicator(
                                rating: (review['rating'] as num).toDouble(),
                                size: 18,
                                ratingCount: 1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Review date
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed on ${DateFormat('MMMM d, y').format(
                        DateTime.parse(review['created_at']).toLocal(),
                      )}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Review content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_quote, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Your Comment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (review['comment'] == null || review['comment'] == '')
                        Text(
                          'No comment provided',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[500],
                          ),
                        )
                      else
                        Text(
                          review['comment'],
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action button to edit if needed
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement edit review functionality if needed
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .primaryColor, // Changed from primary to backgroundColor
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Instead of redefining _buildOrderCard, we'll use the existing one
  // Remove the duplicate method and use the existing implementation

  // ...existing code...
}

// OrderListExtension helper class for virtual IDs
class OrderListExtension {
  final List<Map<String, dynamic>> orders;

  OrderListExtension(this.orders);

  List<Map<String, dynamic>> withVirtualIds() {
    // Generate sequential virtual IDs for better UX
    int virtualId = 1;
    return orders.map((order) {
      // Create a new map with all the original data plus the virtual ID
      return {
        ...order,
        'virtual_id': virtualId++,
        // Convert created_at to timestamp for easier sorting
        'created_at_timestamp':
            DateTime.parse(order['created_at']).millisecondsSinceEpoch,
      };
    }).toList();
  }
}

// Add missing methods for image and animation handling

// Method to safely display images with error handling
Widget _buildSafeImage(
  String? imageUrl, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  IconData fallbackIcon = Icons.image,
}) {
  // Better validation for image URLs
  final bool hasValidImageUrl = imageUrl != null &&
                             imageUrl.trim().isNotEmpty && 
                             (imageUrl.startsWith('http://') || 
                              imageUrl.startsWith('https://') || 
                              imageUrl.startsWith('data:image/'));
  
  if (!hasValidImageUrl) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (width != null && height != null) 
              ? math.min(width, height) / 2 
              : 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }
  
  return Image.network(
    imageUrl!,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      _globalLogger.error('Image error: $error for $imageUrl');
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            fallbackIcon,
            size: (width != null && height != null) 
                ? math.min(width, height) / 2 
                : 40,
            color: Colors.grey[400],
          ),
        ),
      );
    },
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    },
  );
}

// Method to safely display Lottie animations with error handling
Widget _buildSafeLottie(
  String animationPath, {
  double? width,
  double? height,
  bool repeat = true,
  IconData fallbackIcon = Icons.animation,
}) {
  return Lottie.asset(
    animationPath,
    width: width,
    height: height,
    repeat: repeat,
    errorBuilder: (context, error, stackTrace) {
      _globalLogger.error('Lottie error: $error for $animationPath');
      return Container(
        width: width,
        height: height,
        color: Colors.transparent,
        child: Center(
          child: Icon(
            fallbackIcon,
            size: (width != null && height != null)
                ? math.min(width, height) / 2
                : 80,
            color: Colors.grey[400],
          ),
        ),
      );
    },
  );
}
