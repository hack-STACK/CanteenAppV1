import 'package:kantin/Models/menu_cart_item.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/refund_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/utils/api_exception.dart'
    hide TransactionError; // Hide TransactionError from api_exception
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/utils/logger.dart';
import 'package:kantin/Models/transaction_errors.dart'
    as tx_errors; // Add alias

// Add this extension at the top of the file
extension OrderListExtension on List<Map<String, dynamic>> {
  List<Map<String, dynamic>> withVirtualIds() {
    // Sort by created_at first to ensure correct ordering
    final sorted = [...this]..sort((a, b) {
        final aDate = DateTime.parse(a['created_at']);
        final bDate = DateTime.parse(b['created_at']);
        return bDate.compareTo(aDate); // Latest first
      });

    // Assign virtual IDs starting from the latest (highest number)
    for (var i = 0; i < sorted.length; i++) {
      sorted[i] = {
        ...sorted[i],
        'virtual_id': sorted.length - i, // Latest gets highest number
      };
    }
    return sorted;
  }
}

class TransactionService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  Future<int> createTransaction({
    required int studentId,
    required int stallId,
    required double totalAmount,
    required OrderType orderType,
    required List<Map<String, dynamic>> details,
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      _logger.debug('Creating transaction with details: $details');

      final response = await _supabase.rpc('create_transaction', params: {
        'p_student_id': studentId,
        'p_stall_id': stallId,
        'p_total_amount': totalAmount,
        'p_order_type': orderType.name.toLowerCase(),
        'p_delivery_address': deliveryAddress,
        'p_notes': notes,
        'p_details': details.map((detail) {
          // Properly format addon data
          final addons = (detail['addons'] as List<Map<String, dynamic>>?)
                  ?.map((addon) => {
                        'addon_id': addon['addon_id'],
                        'quantity': addon['quantity'],
                        'unit_price': addon['unit_price'],
                        'subtotal': addon['subtotal'],
                        'addon_name': addon['addon_name'], // Add addon name
                      })
                  .toList() ??
              [];

          return {
            'menu_id': detail['menu_id'],
            'menu_name': detail['menu_name'], // Tambahkan ini!
            'quantity': detail['quantity'],
            'unit_price': detail['unit_price'],
            'subtotal': detail['subtotal'],
            'notes': detail['notes'],
            'original_price': detail['original_price'],
            'discounted_price': detail['discounted_price'],
            'applied_discount_percentage':
                detail['applied_discount_percentage'],
            'addons': addons,
          };
        }).toList(),
      });

      return response['transaction_id'];
    } catch (e) {
      _logger.error('Create transaction error:', e);
      throw tx_errors.TransactionError('Failed to create transaction: $e');
    }
  }

  Future<void> updateTransactionPayment(
    int transactionId, {
    required PaymentStatus paymentStatus,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      await _supabase.from('transactions').update({
        'payment_status': paymentStatus.name,
        'payment_method': paymentMethod.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);

      await _supabase
          .from('order_items')
          .update({'status': 'processing'}).eq('transaction_id', transactionId);
    } catch (e) {
      throw tx_errors.TransactionError('Failed to update payment status : $e');
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToOrders(int studentId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .map((orders) {
          if (orders.isEmpty) return [];
          _logger.debug('Received ${orders.length} orders from stream');
          return OrderListExtension(orders).withVirtualIds();
        })
        .asyncMap((orders) async {
          if (orders.isEmpty) return [];

          final List<Map<String, dynamic>> ordersWithDetails = [];
          
          for (var order in orders) {
            try {
              final localCreatedAt = DateTime.parse(order['created_at']).toLocal();

              // Safely handle the details query
              final List<dynamic> details = await _supabase
                  .from('transaction_details')
                  .select('''
                    id,
                    quantity,
                    unit_price,
                    subtotal,
                    notes,
                    menu_name,
                    menu_price,
                    menu_photo,
                    original_price,
                    discounted_price,
                    applied_discount_percentage,
                    addon_name,
                    addon_price,
                    addon_quantity,
                    addon_subtotal
                  ''')
                  .eq('transaction_id', order['id'])
                  .order('created_at', ascending: true);

              // Only add orders with valid details
              if (details.isNotEmpty) {
                ordersWithDetails.add({
                  ...order,
                  'created_at': localCreatedAt.toIso8601String(),
                  'created_at_timestamp': localCreatedAt.millisecondsSinceEpoch,
                  'items': details.map((detail) {
                    // Handle null values and type conversions safely
                    return {
                      ...detail,
                      'addon_quantity': detail['addon_quantity'] ?? 0,
                      'addon_price': (detail['addon_price'] as num?)?.toDouble() ?? 0.0,
                      'addon_subtotal': (detail['addon_subtotal'] as num?)?.toDouble() ?? 0.0,
                      'unit_price': (detail['unit_price'] as num?)?.toDouble() ?? 0.0,
                      'subtotal': (detail['subtotal'] as num?)?.toDouble() ?? 0.0,
                      'original_price': (detail['original_price'] as num?)?.toDouble() ?? 0.0,
                      'discounted_price': (detail['discounted_price'] as num?)?.toDouble() ?? 0.0,
                      'applied_discount_percentage': (detail['applied_discount_percentage'] as num?)?.toDouble() ?? 0.0,
                    };
                  }).toList(),
                });
              }
            } catch (e) {
              _logger.error('Error processing order ${order['id']}: $e');
              // Skip failed orders instead of breaking the entire stream
              continue;
            }
          }

          return ordersWithDetails.isEmpty ? [] : ordersWithDetails.withVirtualIds();
        });
  }

  final RefundService _refundService = RefundService();
  static final bool _debug = false; // Set to false for release mode

  Future<bool> canCreateNewOrder(int studentId) async {
    try {
      final activeOrders = await _supabase
          .from('transactions')
          .select('id')
          .eq('student_id', studentId)
          .not('status', 'in', ['completed', 'cancelled']).count();

      final count = activeOrders.count;
      return count < 5; // Simplified check
    } catch (e) {
      _logger.error('Error checking active orders count', e);
      throw Exception('Failed to check order limit: $e');
    }
  }

  Future<void> createOrderItems({
    required int transactionId,
    required List<CartItem> items,
    required int userId,
  }) async {
    try {
      _logger.info('Creating order items for transaction: $transactionId');

      // Create order items for each cart item
      for (var item in items) {
        // Create main menu order item
        final orderItem = await _supabase
            .from('order_items')
            .insert({
              'transaction_id': transactionId,
              'menu_id': item.menu.id,
              'user_id': userId,
              'stall_id': item.menu.stallId,
              'quantity': item.quantity,
              'status': 'pending',
            })
            .select()
            .single();

        _logger.debug('Created order item: ${orderItem['id']}');

        // Create order items for addons if any
        if (item.selectedAddons.isNotEmpty) {
          for (var addon in item.selectedAddons) {
            await _supabase.from('order_items').insert({
              'transaction_id': transactionId,
              'menu_id': item.menu.id,
              'addon_id': addon.id,
              'user_id': userId,
              'stall_id': item.menu.stallId,
              'quantity': item.quantity,
              'status': 'pending',
            });
            _logger.debug('Created addon order item for addon: ${addon.id}');
          }
        }
      }

      _logger.info('Successfully created all order items');
    } catch (e, stack) {
      _logger.error('Failed to create order items', e, stack);
      throw Exception('Failed to create order items: $e');
    }
  }

  Future<void> updatePaymentStatus(
    int transactionId,
    PaymentStatus status,
  ) async {
    try {
      await _supabase.from('transactions').update({
        'payment_status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);
    } catch (e) {
      throw ApiException('Failed to update payment status: $e');
    }
  }

  Future<void> updateTransactionStatus(
    int transactionId,
    TransactionStatus status,
  ) async {
    try {
      await _supabase.from('transactions').update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);
    } catch (e) {
      throw ApiException('Failed to update transaction status: $e');
    }
  }

  Future<void> cancelOrder(int transactionId, CancellationReason reason) async {
    try {
      final orderData = await _supabase.from('transactions').select('''
            *,
            status,
            payment_status,
            total_amount,
            student_id
          ''').eq('id', transactionId).single();

      final currentStatus = orderData['status'];
      final paymentStatus = orderData['payment_status'];

      // Validate cancellation
      if (currentStatus == TransactionStatus.cancelled.name) {
        throw Exception('This order has already been cancelled');
      }

      if (currentStatus != TransactionStatus.pending.name &&
          currentStatus != TransactionStatus.confirmed.name) {
        throw Exception('This order cannot be cancelled at this stage');
      }

      // Update transaction status with cancellation reason
      final cancelledAt = DateTime.now().toIso8601String();

      await _supabase.from('transactions').update({
        'status': TransactionStatus.cancelled.name,
        'cancellation_reason': reason.name,
        'cancelled_at': cancelledAt,
        'updated_at': cancelledAt,
      }).eq('id', transactionId);

      // Handle refund if payment was made
      if (paymentStatus == PaymentStatus.paid.name) {
        await _supabase.from('transactions').update({
          'payment_status': PaymentStatus.refunded.name,
        }).eq('id', transactionId);

        await _refundService.createRefundRequest(
          transactionId: transactionId,
          reason: 'Order cancelled: ${reason.name}',
          status: RefundStatus.pending.name,
          notes: 'Automatic refund for cancelled order',
        );
      }

      _logger.info('Successfully cancelled order: $transactionId');
    } catch (e) {
      _logger.error('Failed to cancel order', e);
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Add method to check if order can be cancelled
  Future<bool> canCancelOrder(int transactionId) async {
    try {
      final orderData = await _supabase
          .from('transactions')
          .select('status, created_at')
          .eq('id', transactionId)
          .single();

      final status = orderData['status'];
      final createdAt = DateTime.parse(orderData['created_at']);
      final now = DateTime.now();

      // Check if already cancelled
      if (status == TransactionStatus.cancelled.name) {
        return false;
      }

      // Only allow cancellation for pending and confirmed orders
      if (status != TransactionStatus.pending.name &&
          status != TransactionStatus.confirmed.name) {
        return false;
      }

      // Only allow cancellation within 5 minutes for confirmed orders
      if (status == TransactionStatus.confirmed.name) {
        final timeDifference = now.difference(createdAt);
        if (timeDifference.inMinutes > 5) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking cancellation eligibility: $e');
      return false;
    }
  }

  // Add method to get cancellation details
  Future<Map<String, dynamic>?> getCancellationDetails(
      int transactionId) async {
    try {
      final data = await _supabase.from('transactions').select('''
        cancellation_reason,
        cancelled_at,
        payment_status,
        updated_at,
        refund_logs (
          id,
          status,
          created_at,
          notes
        )
      ''').eq('id', transactionId).single();

      return data;
    } catch (e) {
      print('Error getting cancellation details: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveOrders(int studentId) async {
    try {
      _logger.info('Fetching active orders for student: $studentId');

      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            items:transaction_details(
              *,
              menu:menu_id(*),
              addons:transaction_addon_details(
                *,
                addon:addon_id(*)
              )
            )
          ''')
          .eq('student_id', studentId)
          .not('status', 'in', ['completed', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(50); // Add reasonable limit

      _logger.debug('Received ${response.length} active orders');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      _logger.error('Failed to fetch active orders', e, stack);
      throw Exception('Failed to fetch active orders: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderHistory(int studentId) async {
    try {
      _logger.info('Fetching order history for student: $studentId');

      // First get the latest transaction ID
      final latestTransaction = await _supabase
          .from('transactions')
          .select('id')
          .order('id', ascending: false)
          .limit(1)
          .single();

      final latestId = latestTransaction['id'] as int;
      _logger.debug('Latest transaction ID: $latestId');

      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            items:transaction_details(
              *,
              menu:menu_id(*),
              addons:transaction_addon_details(
                *,
                addon:addon_id(*)
              )
            )
          ''')
          .eq('student_id', studentId)
          .inFilter('status', ['completed', 'cancelled'])
          .lte('id',
              latestId) // Add this line to ensure we get all transactions up to the latest
          .order('created_at', ascending: false);

      _logger.debug('Order history response: $response');

      final results = List<Map<String, dynamic>>.from(response);
      _logger.info('Fetched ${results.length} orders for student $studentId');
      return results;
    } catch (e, stack) {
      _logger.error('Error fetching order history', e, stack);
      throw Exception('Failed to fetch order history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderProgressHistory(
      int transactionId) async {
    try {
      final response = await _supabase
          .from('transaction_progress')
          .select()
          .eq('transaction_id', transactionId)
          .order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to load order progress history: $e';
    }
  }

  Future<void> deleteOrderHistory(int transactionId) async {
    try {
      // First check if the order is completed or cancelled
      final orderData = await _supabase
          .from('transactions')
          .select('status')
          .eq('id', transactionId)
          .single();

      final status = orderData['status'];
      if (status != 'completed' && status != 'cancelled') {
        throw 'Can only delete completed or cancelled orders';
      }

      // Delete the order and its related records
      await _supabase.rpc('begin_transaction');
      try {
        // Delete progress history
        await _supabase
            .from('transaction_progress')
            .delete()
            .eq('transaction_id', transactionId);

        // Delete transaction details
        await _supabase
            .from('transaction_details')
            .delete()
            .eq('transaction_id', transactionId);

        // Delete the transaction
        await _supabase.from('transactions').delete().eq('id', transactionId);

        await _supabase.rpc('commit_transaction');
      } catch (e) {
        await _supabase.rpc('rollback_transaction');
        rethrow;
      }
    } catch (e) {
      throw 'Failed to delete order history: $e';
    }
  }

  Future<void> _createTransactionDetails(
      int transactionId, List<CartItem> items) async {
    try {
      final detailsList = items.map((item) {
        final originalPrice = item.menu.price;
        final effectivePrice = item.menu.effectivePrice;
        final discountPercentage = item.menu.discountPercent;
        final total = effectivePrice * item.quantity; // Calculate total here

        return {
          'transaction_id': transactionId,
          'menu_id': item.menu.id,
          'quantity': item.quantity,
          'unit_price': effectivePrice,
          'subtotal': total, // Use calculated total
          'notes': item.note,
          'applied_discount_percentage': discountPercentage,
          'original_price': originalPrice,
          'discounted_price': effectivePrice
        };
      }).toList();

      await _supabase.from('transaction_details').insert(detailsList);
    } catch (e) {
      throw ApiException('Failed to create transaction details: $e');
    }
  }

  Stream<List<Transaction>> getStallTransactions(int stallId) {
    _logger.debug('Fetching transactions for stall: $stallId');

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('stall_id', stallId)
        .order('created_at', ascending: false)
        .asyncMap((response) async {
          _logger.debug('Raw Supabase response: $response');

          final List<Transaction> transactions = [];

          for (final json in response) {
            final details =
                await _supabase.from('transaction_details').select('''
                  *,
                  menu (*),
                  transaction_addon_details (
                    *,
                    addon:food_addons (*)
                  )
                ''').eq('transaction_id', json['id']);

            _logger.debug(
                'Fetched details for transaction ${json['id']}: $details');

            transactions.add(Transaction.fromJson({
              ...json,
              'transaction_details': details,
            }));
          }

          return transactions;
        });
  }

  Stream<List<Transaction>> subscribeToNewOrders(int stallId) {
    if (_debug) print('Subscribing to new orders for stall: $stallId');

    return _supabase
        .from('transactions')
        .select('''
        *,
        transaction_details (
          *,
          menu (
            id,
            food_name,
            price,
            photo,
            stall:stall_id (*)
          )
        )
      ''')
        .eq('stall_id', stallId)
        .eq('status', TransactionStatus.pending.name)
        .order('created_at', ascending: false)
        .asStream()
        .map((data) {
          if (_debug) print('New orders data received: $data');

          try {
            return data.map((item) => Transaction.fromJson(item)).toList();
          } catch (e) {
            print('Error processing orders: $e');
            return <Transaction>[];
          }
        });
  }

  Future<void> updateOrderStatus(
      int transactionId, TransactionStatus status) async {
    try {
      _logger.info('Updating order $transactionId to status: ${status.name}');

      await _supabase.from('transactions').update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);

      await _supabase.from('transaction_progress').insert({
        'transaction_id': transactionId,
        'status': status.name,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.info('Successfully updated order status');
    } catch (e, stack) {
      _logger.error('Failed to update order status: $e', stack);
      throw ApiException('Failed to update order status: $e');
    }
  }

  Stream<List<Transaction>> getStudentTransactions(int studentId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .map((list) => list.map((item) => Transaction.fromJson(item)).toList());
  }

  Future<Map<String, dynamic>> getOrderDetailsById(int orderId) async {
    try {
      _logger.info('Fetching detailed order info for ID: $orderId');

      final response = await _supabase.from('transaction_details').select('''
            id,
            transaction_id,
            menu_id,
            quantity,
            unit_price,
            subtotal,
            notes,
            created_at,
            applied_discount_percentage,
            original_price,
            discounted_price,
            transaction:transaction_id(
              payment_method,
              payment_status
            ),
            menu:menu_id (
              id, 
              food_name,
              photo,
              price,
              stall:stalls (*)
            )
          ''').eq('transaction_id', orderId);

      _logger.debug('Raw transaction details response: $response');

      // Transform each item to ensure numeric fields are properly handled
      final items = (response as List).map((item) {
        // Get the main menu prices
        final originalPrice = item['original_price']?.toString();
        final discountedPrice = item['discounted_price']?.toString();
        final discountPercentage =
            item['applied_discount_percentage']?.toString();

        // Calculate addons total
        final addonItems = (item['addon_items'] as List?)?.map((addon) {
              return {
                ...addon,
                'quantity': addon['quantity'] ?? 1,
                'unit_price': (addon['unit_price'] as num?)?.toDouble() ?? 0.0,
                'subtotal': (addon['subtotal'] as num?)?.toDouble() ?? 0.0,
              };
            }).toList() ??
            [];

        _logger.debug(
            'Addon items for menu item ${item['menu']['food_name']}: $addonItems');

        return {
          ...item,
          'original_price': originalPrice != null
              ? double.parse(originalPrice)
              : item['menu']['price'],
          'discounted_price': discountedPrice != null
              ? double.parse(discountedPrice)
              : item['unit_price'],
          'applied_discount_percentage': discountPercentage != null
              ? double.parse(discountPercentage)
              : 0.0,
          'addon_items': addonItems,
        };
      }).toList();

      _logger.debug('Transformed items: $items');

      return {'id': orderId, 'items': items};
    } catch (e, stack) {
      _logger.error('Failed to fetch order details', e, stack);
      throw Exception('Failed to fetch order details: $e');
    }
  }

  Future<List<TransactionDetail>> getTransactionDetails(
      int transactionId) async {
    try {
      final response = await _supabase.from('transaction_details').select('''
            *,
            menu (*)
          ''').eq('transaction_id', transactionId);

      return (response as List)
          .map((item) => TransactionDetail.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching transaction details: $e');
      return [];
    }
  }

  Future<int> createTransactionDetail({
    required int transactionId,
    required int menuId,
    required int quantity,
    required double unitPrice,
    required double subtotal,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('transaction_details')
          .insert({
            'transaction_id': transactionId,
            'menu_id': menuId,
            'quantity': quantity,
            'unit_price': unitPrice,
            'subtotal': subtotal,
            'notes': notes,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to create transaction details: $e');
    }
  }

  Future<void> createTransactionAddonDetail({
    required int transactionDetailId,
    required int addonId,
    required int quantity,
    required double unitPrice,
    required double subtotal,
  }) async {
    try {
      await _supabase.from('transaction_addon_details').insert({
        'transaction_detail_id': transactionDetailId,
        'addon_id': addonId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      });
    } catch (e) {
      throw Exception('Failed to create transaction addon details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllOrders(int studentId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            items:transaction_details (
              *,
              menu:menu_id(*),
              addons:transaction_addon_details(
                *,
                addon:addon_id(*)
              )
            )
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      _logger.error('Failed to fetch orders', e, stack);
      throw Exception('Failed to fetch orders: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOrderTrackingDetails(
      int transactionId) async {
    try {
      _logger.info(
          'Fetching static order details for transaction: $transactionId');

      final response = await _supabase.from('transaction_details').select('''
            id,
            transaction_id,
            menu_id,
            menu_name,
            quantity,
            unit_price,
            subtotal,
            notes,
            original_price,
            discounted_price,
            applied_discount_percentage,
            addon_name,
            addon_price,
            addon_quantity,
            addon_subtotal,
            created_at,
            transaction:transaction_id(
              payment_method,
              payment_status
            ),
            menu:menu_id (
              id,
              food_name,
              photo,
              description,
              price,
              stall:stalls (
                id,
                nama_stalls,
                image_url,
                Banner_img,
                deskripsi
              )
            )
          ''').eq('transaction_id', transactionId);

      // Process the response to include addons in a more structured way
      final processedItems = response.map((item) {
        // Only create addon object if addon data exists
        Map<String, dynamic>? addon;
        if (item['addon_name'] != null && item['addon_price'] != null) {
          addon = {
            'name': item['addon_name'],
            'price': item['addon_price'],
            'quantity': item['addon_quantity'] ?? 1,
            'subtotal': item['addon_subtotal'] ??
                (item['addon_price'] * (item['addon_quantity'] ?? 1)),
          };
        }

        return {
          ...item,
          'addons': addon != null ? [addon] : [], // Include addon as array if exists
        };
      }).toList();

      _logger.debug('Processed items with addons: $processedItems');

      return {
        'success': true,
        'items': processedItems,
      };
    } catch (e, stack) {
      _logger.error('Error fetching order tracking details', e, stack);
      return {
        'success': false,
        'error': e.toString(),
        'items': [],
      };
    }
  }

  Future<void> createNewTransaction({
    required int studentId,
    required int stallId,
    required List<CartItem> menuItems,
    required String paymentStatus,
    required double totalAmount, // Add this parameter
    required OrderType orderType,
    String? deliveryAddress,
  }) async {
    try {
      // Start a Supabase transaction
      final transaction = await _supabase
          .from('transactions')
          .insert({
            'student_id': studentId,
            'stall_id': stallId,
            'status': 'pending',
            'payment_status': paymentStatus,
            'total_amount': totalAmount, // Add this field
            'order_type': orderType.name,
            'delivery_address': deliveryAddress,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final transactionId = transaction['id'] as int;

      // Create transaction details with validation
      for (var item in menuItems) {
        if (item.menu.foodName.trim().isEmpty) {
          throw tx_errors.TransactionError(
            'Menu name is required for all items',
            code: 'VALIDATION_ERROR',
          );
        }

        final detailsData = {
          'transaction_id': transactionId,
          'menu_id': item.menu.id,
          'menu_name': item.menu.foodName.trim(),
          'menu_price': item.menu.price,
          'menu_photo': item.menu.photo ?? '',
          'quantity': item.quantity,
          'unit_price': item.discountedPrice ?? item.menu.price,
          'subtotal': (item.discountedPrice ?? item.menu.price) * item.quantity,
          'notes': item.note ?? '',
          'applied_discount_percentage': item.discountPercentage ?? 0.0,
          'original_price': item.originalPrice ?? item.menu.price,
          'discounted_price': item.discountedPrice ?? item.menu.price,
        };

        // Include addon information with validation
        if (item.selectedAddons.isNotEmpty) {
          final addon = item.selectedAddons.first;
          if (addon.addonName.trim().isEmpty) {
            throw tx_errors.TransactionError(
              'Addon name is required',
              code: 'VALIDATION_ERROR',
            );
          }

          detailsData.addAll({
            'addon_name': addon.addonName.trim(),
            'addon_price': addon.price,
            'addon_quantity': item.quantity,
            'addon_subtotal': addon.price * item.quantity,
          });
        }

        await _supabase.from('transaction_details').insert(detailsData);
      }

      _logger.info('Successfully created transaction with ID: $transactionId');
    } catch (e) {
      _logger.error('Failed to create transaction:', e);
      throw tx_errors.TransactionError(
        'Failed to create transaction: $e',
        originalError: e,
      );
    }
  }
}