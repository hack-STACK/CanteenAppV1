import 'package:kantin/Models/menu_cart_item.dart';
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

        // Insert addons if any - Fixed the addons property access
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

      // Updated query to include discount fields
      final response = await _client.from('transaction_details').select('''
        id,
        transaction_id,
        menu_id,
        quantity,
        unit_price,
        subtotal,
        notes,
        created_at,
        addon_name,
        addon_price,
        addon_quantity,
        addon_subtotal,
        original_price,            
        discounted_price,
        applied_discount_percentage,
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
          stall_id
        ),
        transaction:transaction_id (
          id,
          student_id,
          status,
          order_type,
          created_at,
          student:student_id (
            id,
            studentName:nama_siswa,
            address:alamat,
            phone:telp,
            photo:foto
          )
        )
      ''').eq('transaction_id', orderId).order('created_at');

      if (response == null) {
        _logger.error('Null response received when fetching order items');
        throw Exception('Failed to fetch order items: Null response');
      }

      _logger.debug('Received ${response.length} order items');

      final List<OrderItem> items = [];
      for (var item in response) {
        try {
          final menu = item['menu'];
          if (menu == null) {
            _logger.info('Menu data is null for order item ${item['id']}');
            continue;
          }

          // Ensure the menu has a stall_id
          if (menu['stall_id'] == null) {
            _logger.info('Stall ID is missing for menu ${menu['id']}');
            menu['stall_id'] = 0;
          }

          final quantity = item['quantity'] ?? 1;

          // Get the discounted price from transaction_details
          // If no discounted price is available, use unit_price, then menu price
          double unitPrice;
          double originalPrice;
          double appliedDiscountPercentage = 0.0;
          
          // Get original and discounted prices from transaction details
          if (item['original_price'] != null && item['discounted_price'] != null) {
            originalPrice = (item['original_price'] is int)
                ? (item['original_price'] as int).toDouble()
                : (item['original_price'] as num).toDouble();
                
            unitPrice = (item['discounted_price'] is int)
                ? (item['discounted_price'] as int).toDouble() 
                : (item['discounted_price'] as num).toDouble();
                
            if (item['applied_discount_percentage'] != null) {
              appliedDiscountPercentage = (item['applied_discount_percentage'] is int)
                  ? (item['applied_discount_percentage'] as int).toDouble()
                  : (item['applied_discount_percentage'] as num).toDouble();
            }
          } else {
            // Fallback to unit_price and menu price
            unitPrice = (item['unit_price'] is int)
                ? (item['unit_price'] as int).toDouble()
                : (item['unit_price'] ?? menu['price'] ?? 0).toDouble();
            originalPrice = (menu['price'] as num?)?.toDouble() ?? unitPrice;
          }

          final subtotal = (item['subtotal'] is int)
              ? (item['subtotal'] as int).toDouble()
              : item['subtotal']?.toDouble() ?? (unitPrice * quantity);

          // Create a modified menu object that includes discount info
          final menuWithDiscount = Menu.fromJson({
            ...menu,
            'original_price': originalPrice,
            'discounted_price': unitPrice,
            'discount_percent': appliedDiscountPercentage,
            'has_discount': originalPrice > unitPrice,
          });

          List<OrderAddonDetail> addonDetails = [];
          
          // Handle addon data from direct fields in transaction_details
          if (item['addon_name'] != null && item['addon_price'] != null) {
            final addonQuantity = item['addon_quantity'] ?? 1;
            final addonPrice = (item['addon_price'] is int)
                ? (item['addon_price'] as int).toDouble()
                : (item['addon_price'] ?? 0).toDouble();
                
            final addonSubtotal = (item['addon_subtotal'] is int)
                ? (item['addon_subtotal'] as int).toDouble()
                : item['addon_subtotal']?.toDouble() ?? (addonPrice * addonQuantity);
                
            addonDetails.add(OrderAddonDetail(
              id: "${item['id']}_addon",
              addonId: 0,
              addonName: item['addon_name'],
              price: addonPrice,
              quantity: addonQuantity,
              unitPrice: addonPrice,
              subtotal: addonSubtotal,
            ));
          }

          items.add(OrderItem(
            id: item['id'].toString(),
            orderId: orderId,
            menu: menuWithDiscount, // Use the enhanced menu object
            quantity: quantity,
            unitPrice: unitPrice,
            originalUnitPrice: originalPrice, // Save the original price
            discountPercentage: appliedDiscountPercentage,
            subtotal: subtotal,
            status: item['transaction']['status'] ?? 'pending',
            notes: item['notes'],
            addons: addonDetails,
            createdAt: DateTime.parse(item['created_at'] ?? item['transaction']['created_at']),
          ));
        } catch (itemError, stack) {
          _logger.error('Error processing order item: $itemError');
          _logger.error('Stack trace: $stack');
          continue;
        }
      }

      return items;
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

  // Fetch transaction details
  Future<List<TransactionDetail>> fetchTransactionDetails(
      int transactionId) async {
    try {
      final response = await _client.from('transaction_details').select('''
            *,
            menu:menu_id(*),
            transaction:transaction_id(*)
          ''').eq('transaction_id', transactionId);

      return (response as List)
          .map((detail) => TransactionDetail.fromJson(detail))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }

  // Handle discounts
  Future<void> applyDiscount(int transactionId, double discountAmount) async {
    try {
      final response = await _client
          .from('transactions')
          .select('total_amount')
          .eq('id', transactionId)
          .single();

      final totalAmount = response['total_amount'] as double;
      final newTotalAmount = totalAmount - discountAmount;

      await _client
          .from('transactions')
          .update({'total_amount': newTotalAmount}).eq('id', transactionId);
    } catch (e) {
      throw Exception('Failed to apply discount: $e');
    }
  }
}