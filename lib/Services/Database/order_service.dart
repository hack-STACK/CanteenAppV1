import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Models/orderItem.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;
  final Logger _logger = Logger();

  // Local cache for food items and addons
  final Map<int, Menu> _foodCache = {};
  final Map<int, FoodAddon> _addonCache = {};

  Stream<List<Transaction>> getStallOrders(int stallId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('stall_id', stallId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map<Transaction>((json) => Transaction.fromJson(json))
            .toList());
  }

  Future<void> updateOrderStatus(
      int orderId, TransactionStatus newStatus) async {
    try {
      await _client.from('transactions').update({
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<Transaction> createOrder({
    required int studentId,
    required int stallId,
    required OrderType orderType,
    required double totalAmount,
    required List<TransactionDetail> details,
    String? notes,
    String? deliveryAddress,
  }) async {
    try {
      final response = await _client
          .from('transactions')
          .insert({
            'student_id': studentId,
            'stall_id': stallId,
            'status': TransactionStatus.pending.name,
            'payment_status': PaymentStatus.unpaid.name,
            'order_type': orderType.toJson(),
            'total_amount': totalAmount,
            'notes': notes,
            'delivery_address': deliveryAddress,
          })
          .select()
          .single();

      final transactionId = response['id'] as int;

      // Insert transaction details
      for (var detail in details) {
        final detailResponse = await _client
            .from('transaction_details')
            .insert({
              'transaction_id': transactionId,
              'menu_id': detail.menuId,
              'quantity': detail.quantity,
              'unit_price': detail.unitPrice,
              'subtotal': detail.subtotal,
              'notes': detail.notes,
            })
            .select()
            .single();

        final detailId = detailResponse['id'] as int;

        // Insert addons if any
        for (var addon in detail.addons) {
          await _client.from('transaction_addon_details').insert({
            'transaction_detail_id': detailId,
            'addon_id': addon.addonId,
            'quantity': addon.quantity,
            'unit_price': addon.unitPrice,
            'subtotal': addon.subtotal,
          });
        }
      }

      return Transaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  Future<List<Transaction>> getStudentOrders(int studentId) async {
    try {
      final response = await _client
          .from('transactions')
          .select('''
            *,
            transaction_details (
              *,
              menu (*),
              transaction_addon_details (*)
            )
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map<Transaction>((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch student orders: $e');
    }
  }

  Stream<Transaction> getSingleOrderStream(int orderId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((event) => Transaction.fromJson(event.first));
  }

  Future<void> sendOrderNotification(int orderId, String message) async {
    try {
      await _client.from('notifications').insert({
        'order_id': orderId,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Future<List<TransactionDetail>> getOrderDetails(int orderId) async {
    final response = await _client.from('transaction_details').select('''
        *,
        menu:menu_id(*),
        addons:transaction_addon_details(
          *,
          addon:addon_id(*)
        )
      ''').eq('transaction_id', orderId);

    return (response as List)
        .map((detail) => TransactionDetail.fromJson(detail))
        .toList();
  }

  Future<Transaction> getOrderById(int orderId) async {
    final response = await _client.from('transactions').select('''
        *,
        details:transaction_details(
          *,
          menu:menu_id(*),
          addons:transaction_addon_details(
            *,
            addon:addon_id(*)
          )
        ),
        customer:customer_id(*)
      ''').eq('id', orderId).single();

    return Transaction.fromJson(response);
  }

  Future<Menu?> getFoodById(int menuId) async {
    _logger.info('Getting food item for ID: $menuId');

    // Check cache first
    if (_foodCache.containsKey(menuId)) {
      _logger.info('Cache hit for food ID: $menuId');
      return _foodCache[menuId];
    }

    try {
      // Get from database
      _logger.info('Cache miss, fetching from database for food ID: $menuId');
      final response =
          await _client.from('menu').select('*').eq('id', menuId).single();

      final menu = Menu.fromJson(response);
      _logger.info('Caching food item: ${menu.foodName}');
      _foodCache[menuId] = menu;
      return menu;
    } catch (e) {
      _logger.error('Error fetching food item: $e');
      return null;
    }
  }

  Future<FoodAddon?> getAddonById(int addonId) async {
    _logger.info('Getting addon for ID: $addonId');

    // Check cache first
    if (_addonCache.containsKey(addonId)) {
      _logger.info('Cache hit for addon ID: $addonId');
      return _addonCache[addonId];
    }

    try {
      _logger.info('Cache miss, fetching from database for addon ID: $addonId');
      final response = await _client
          .from('food_addons')
          .select('*')
          .eq('id', addonId)
          .single();

      final addon = FoodAddon.fromJson(response);
      _logger.info('Caching addon: ${addon.name}');
      _addonCache[addonId] = addon;
      return addon;
    } catch (e) {
      _logger.error('Error fetching addon: $e');
      return null;
    }
  }

  // Method to clear cache if needed
  void clearCache() {
    _logger.info('Clearing cache');
    _foodCache.clear();
    _addonCache.clear();
  }

  Future<StudentModel?> getStudentById(int studentId) async {
    final response =
        await _client.from('students').select('*').eq('id', studentId).single();
    return StudentModel.fromJson(response);
  }

  Future<List<OrderItem>> createOrderItems({
    required List<OrderItem> items,
    required int orderId,
  }) async {
    try {
      final orderItemsData = items
          .map((item) => {
                'transaction_id': orderId,
                'menu_id': item.menuId,
                'addon_id': item.addonId,
                'user_id': item.userId,
                'stall_id': item.stallId,
                'quantity': item.quantity,
                'unit_price': item.unitPrice, // Add unit_price to the insert
                'status': 'pending',
              })
          .toList();

      final response =
          await _client.from('order_items').insert(orderItemsData).select('''
            *,
            menu:menu_id(*),
            addon:addon_id(*),
            user:user_id(*)
          ''');

      return (response as List)
          .map((json) => OrderItem.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to create order items: $e');
    }
  }

  // Add this method
  Future<List<OrderItem>> createOrderItemsForTransaction({
    required int transactionId,
    required List<CartItem> items,
  }) async {
    try {
      _logger.info('Creating order items for transaction: $transactionId');

      final List<Map<String, dynamic>> orderItemsData = items.map((item) {
        return {
          'transaction_id': transactionId, // Keep as int
          'menu_id': item.menu.id, // Keep as int
          'addon_id': item.selectedAddons.isNotEmpty
              ? item.selectedAddons.first.id // Keep as int
              : null,
          'user_id': _client.auth.currentUser?.id,
          'stall_id': item.menu.stallId, // Keep as int
          'quantity': item.quantity,
          'status': 'pending',
        };
      }).toList();

      _logger.info('Inserting ${orderItemsData.length} order items');

      final response =
          await _client.from('order_items').insert(orderItemsData).select('''
            *,
            menu:menu_id(*),
            addon:addon_id(*),
            user:user_id(*)
          ''');

      _logger.info('Successfully created order items');

      return (response as List)
          .map((json) => OrderItem.fromJson(json))
          .toList();
    } catch (e) {
      _logger.error('Error creating order items: $e');
      throw Exception('Failed to create order items: $e');
    }
  }

  // Get order items by transaction
  Future<List<OrderItem>> getOrderItems(int orderId) async {
    try {
      _logger.info('Fetching order items for order #$orderId');

      final response = await _client.from('order_items').select('''
        id,
        quantity,
        unit_price,
        menu:menu_id (
          id,
          food_name,
          price,
          photo,
          description,
          is_available,
          type,
          category,
          rating,
          total_ratings,
          stall:stall_id (
            id,
            nama_stalls
          )
        ),
        addon:food_addons( 
          id,
          addon_name,
          price,
          is_available,
          Description
        ),
        status,
        transaction_id,
        created_at
      ''').eq('transaction_id', orderId).order('created_at');

      _logger.debug('Received ${response.length} order items');

      return response.map((item) {
        final menu = item['menu'];
        final addon = item['addon'];
        final quantity = item['quantity'] ?? 1;
        final unitPrice =
            (item['unit_price'] ?? menu?['price'] ?? 0).toDouble();
        final subtotal = unitPrice * quantity;

        List<OrderAddonDetail> addonDetails = [];

        if (addon != null) {
          final addonPrice = (addon['price'] as num?)?.toDouble() ?? 0.0;
          addonDetails.add(OrderAddonDetail(
            id: addon['id'].toString(),
            addonId: addon['id'],
            addonName: addon['addon_name'] ?? 'Unknown Addon',
            price: addonPrice,
            quantity: quantity,
            unitPrice: addonPrice,
            subtotal: addonPrice * quantity,
          ));
        }

        return OrderItem(
          id: item['id'].toString(),
          orderId: item['transaction_id'],
          menu: menu != null ? Menu.fromJson(menu) : null,
          quantity: quantity,
          unitPrice: unitPrice,
          subtotal: subtotal +
              (addonDetails.isNotEmpty ? addonDetails[0].subtotal : 0),
          status: item['status'] ?? 'pending',
          addons: addonDetails,
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();
    } catch (e, stack) {
      _logger.error('Failed to fetch order items', e, stack);
      throw Exception('Failed to fetch order items: $e');
    }
  }

  // Stream order items for real-time updates
  Stream<List<OrderItem>> streamStallOrderItems(int stallId) {
    return _client
        .from('order_items')
        .stream(primaryKey: ['id'])
        .eq('stall_id', stallId)
        .order('created_at')
        .map((data) =>
            data.map<OrderItem>((json) => OrderItem.fromJson(json)).toList());
  }

  // Update order item status
  Future<void> updateOrderItemStatus(int itemId, String newStatus) async {
    try {
      await _client
          .from('order_items')
          .update({'status': newStatus}).eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to update order item status: $e');
    }
  }
}
