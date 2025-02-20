import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/refund_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/utils/api_exception.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/utils/logger.dart'; // Add this import
// Use alias
import 'package:kantin/Services/Database/studentService.dart';

class TransactionService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  Future<int> createTransaction({
    required int studentId,
    required int stallId,
    required double totalAmount,
    required OrderType orderType,
    required List<CartItem> items,
    String? deliveryAddress,
    String? notes,
  }) async {
    try {
      _logger.info('Creating transaction...');

      // Begin transaction creation
      final transactionResponse = await _supabase
          .from('transactions')
          .insert({
            'student_id': studentId,
            'stall_id': stallId,
            'total_amount': totalAmount,
            'order_type': orderType.name,
            'delivery_address': deliveryAddress,
            'notes': notes,
            'status': 'pending',
            'payment_status': 'unpaid',
          })
          .select()
          .single();

      final transactionId = transactionResponse['id'];
      _logger.info('Created transaction: $transactionId');

      // Create order items
      for (var item in items) {
        // Create main menu order item
        await _supabase.from('order_items').insert({
          'transaction_id': transactionId,
          'menu_id': item.menu.id,
          'user_id': await _getUserId(studentId),
          'stall_id': stallId,
          'quantity': item.quantity,
          'status': 'pending',
        });

        // Create order items for addons
        for (var addon in item.selectedAddons) {
          await _supabase.from('order_items').insert({
            'transaction_id': transactionId,
            'menu_id': item.menu.id,
            'addon_id': addon.id,
            'user_id': await _getUserId(studentId),
            'stall_id': stallId,
            'quantity': item.quantity,
            'status': 'pending',
          });
        }
      }

      // Create transaction details
      for (var item in items) {
        final detailResponse = await _supabase
            .from('transaction_details')
            .insert({
              'transaction_id': transactionId,
              'menu_id': item.menu.id,
              'quantity': item.quantity,
              'unit_price': item.menu.price,
              'subtotal': item.menu.price * item.quantity,
              'notes': item.note,
            })
            .select()
            .single();

        final detailId = detailResponse['id'];

        // Create addon details if any
        if (item.selectedAddons.isNotEmpty) {
          for (var addon in item.selectedAddons) {
            await _supabase.from('transaction_addon_details').insert({
              'transaction_detail_id': detailId,
              'addon_id': addon.id,
              'quantity': item.quantity,
              'unit_price': addon.price,
              'subtotal': addon.price * item.quantity,
            });
          }
        }
      }

      return transactionId;
    } catch (e, stack) {
      _logger.error('Failed to create transaction', e, stack);
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<int> _getUserId(int studentId) async {
    try {
      final response = await _supabase
          .from('students')
          .select('id_user')
          .eq('id', studentId)
          .single();
      return response['id_user'];
    } catch (e) {
      _logger.error('Failed to get user ID', e);
      throw Exception('Failed to get user ID: $e');
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

      // Update order items status
      await _supabase
          .from('order_items')
          .update({'status': 'processing'}).eq('transaction_id', transactionId);
    } catch (e) {
      _logger.error('Failed to update payment status', e);
      throw Exception('Failed to update payment status: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToOrders(int studentId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .asyncMap((orders) async {
          _logger.debug('Received ${orders.length} orders from stream');

          final List<Map<String, dynamic>> ordersWithDetails =
              await Future.wait(
            orders.map((order) async {
              final List<dynamic> details = await _supabase
                  .from('transaction_details')
                  .select('''
                    id,
                    quantity,
                    unit_price,
                    subtotal,
                    notes,
                    menu:menu_id (
                      id,
                      food_name,
                      price,
                      photo,
                      stall:stall_id (*)
                    ),
                    addons:transaction_addon_details (
                      id,
                      quantity,
                      unit_price,
                      subtotal,
                      addon:addon_id (
                        id,
                        addon_name,
                        price
                      )
                    )
                  ''')
                  .eq('transaction_id', order['id'])
                  .order('created_at', ascending: true);

              return {
                ...order,
                'items': details,
                'created_at_timestamp':
                    DateTime.parse(order['created_at']).millisecondsSinceEpoch,
              };
            }),
          );

          ordersWithDetails.sort((a, b) => (b['created_at_timestamp'] as int)
              .compareTo(a['created_at_timestamp'] as int));

          return ordersWithDetails;
        });
  }

  final RefundService _refundService = RefundService();
  final StudentService _studentService = StudentService();
  static final bool _debug = false; // Set to false for release mode

  // Add helper method to convert enum to database value
  String _getStatusString(TransactionStatus status) {
    return status.toString().split('.').last;
  }

  Future<Map<String, dynamic>> _handleDatabaseError(dynamic error) async {
    final message = error.toString();
    if (message.contains('not found')) {
      throw ApiException('Resource not found. Please try again.');
    } else if (message.contains('duplicate')) {
      throw ApiException('This transaction already exists.');
    } else if (message.contains('permission denied')) {
      throw ApiException('You don\'t have permission to perform this action.');
    }
    throw ApiException('An unexpected error occurred: $message');
  }

  Future<bool> canCreateNewOrder(int studentId) async {
    try {
      final activeOrders = await _supabase
          .from('transactions')
          .select('id')
          .eq('student_id', studentId)
          .not('status', 'in', ['completed', 'cancelled']).count();

      return (activeOrders.count ?? 0) < 5;
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
        // First create the main transaction detail
        final transactionDetail = {
          'transaction_id': transactionId,
          'menu_id': item.menu.id,
          'quantity': item.quantity,
          'unit_price': item.menu.price,
          'subtotal': item.menu.price * item.quantity,
          'notes': item.note,
        };

        // If there are addons, create addon details for each addon
        final addonDetails = item.selectedAddons
            .where((addon) => addon.id != null)
            .map((addon) => {
                  'transaction_id': transactionId,
                  'menu_id': item.menu.id,
                  'addon_id':
                      addon.id!, // Force non-null since we filtered nulls
                  'quantity': item.quantity,
                  'unit_price': addon.price,
                  'subtotal': addon.price * item.quantity,
                })
            .toList();

        return {
          'detail': transactionDetail,
          'addons': addonDetails,
        };
      }).toList();

      await _supabase.rpc('begin_transaction');

      try {
        // Insert all transaction details
        for (final detail in detailsList) {
          await _supabase.from('transaction_details').insert(detail['detail']!);

          // Insert addon details if any
          final addons = detail['addons'] as List;
          if (addons.isNotEmpty) {
            await _supabase.from('transaction_addon_details').insert(addons);
          }
        }

        await _supabase.rpc('commit_transaction');
      } catch (e) {
        await _supabase.rpc('rollback_transaction');
        rethrow;
      }
    } catch (e) {
      throw ApiException('Failed to create transaction details: $e');
    }
  }

  // In transaction_service.dart
  Stream<List<Transaction>> getStallTransactions(int stallId) {
    print('Fetching transactions for stall: $stallId'); // Debug print

    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('stall_id', stallId)
        .order('created_at', ascending: false)
        .asyncMap((response) async {
          print('Raw Supabase response: $response'); // Debug print

          final List<Transaction> transactions = [];

          for (final json in response) {
            // Fetch transaction details
            final details =
                await _supabase.from('transaction_details').select('''
                  *,
                  menu (*),
                  transaction_addon_details (
                    *,
                    addon:food_addons (*)
                  )
                ''').eq('transaction_id', json['id']);

            print(
                'Fetched details for transaction ${json['id']}: $details'); // Debug print

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
            menu (*),
            transaction_addon_details (
              *,
              addon:food_addons (*)
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
      _logger.info('Fetching order details for ID: $orderId');

      // Get transaction with items and addons
      final response = await _supabase.from('transactions').select('''
          *,
          items:order_items (
            id,
            quantity,
            status,
            menu:menu_id (
              id,
              food_name,
              price,
              photo
            ),
            addon:addon_id (
              id,
              addon_name,
              price,
              description
            ),
            addon_items:transaction_addon_details (
              id,
              quantity,
              unit_price,
              subtotal,
              addon:addon_id (
                id,
                addon_name,
                price
              )
            )
          )
        ''').eq('id', orderId).single();
      _logger.debug('Order details response: $response');
      return response;
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
}
