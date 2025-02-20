import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Services/Database/refund_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/utils/api_exception.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/utils/logger.dart'; // Add this import
import 'package:kantin/utils/error_handler.dart' as error_handler; // Use alias
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Database/studentService.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RefundService _refundService = RefundService();
  final StudentService _studentService = StudentService();
  static bool _debug = false; // Set to false for release mode

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

  Future<int> createTransaction({
    required int studentId,
    required int stallId,
    required double totalAmount,
    required List<CartItem> items,
    required OrderType orderType, // Add this parameter
    String? notes,
    String? deliveryAddress,
  }) async {
    try {
      final response = await _supabase
          .from('transactions')
          .insert({
            'student_id': studentId,
            'stall_id': stallId,
            'total_amount': totalAmount,
            'status': TransactionStatus.pending.name,
            'payment_status': PaymentStatus.unpaid.name,
            'order_type': orderType.name,
            'notes': notes,
            'delivery_address':
                orderType == OrderType.delivery ? deliveryAddress : null,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final transactionId = response['id'] as int;
      await _createTransactionDetails(transactionId, items);

      return transactionId;
    } catch (e) {
      throw ApiException('Failed to create transaction: ${e.toString()}');
    }
  }

  // Add this method for updating payment status
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
    } catch (e, stackTrace) {
      throw ApiException('Failed to update payment status: $e');
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
      // First check current order status and get order details
      final orderData = await _supabase
          .from('transactions')
          .select('''
            *,
            status,
            payment_status,
            total_amount,
            student_id
          ''')
          .eq('id', transactionId)
          .single();

      final currentStatus = orderData['status'];
      final paymentStatus = orderData['payment_status'];
      final totalAmount = orderData['total_amount'];
      final studentId = orderData['student_id'];

      // Validate cancellation
      if (currentStatus == TransactionStatus.cancelled.name) {
        throw Exception('This order has already been cancelled');
      }

      if (currentStatus != TransactionStatus.pending.name &&
          currentStatus != TransactionStatus.confirmed.name) {
        throw Exception('This order cannot be cancelled at this stage');
      }

      // Begin transaction
      await _supabase.rpc('begin_transaction');

      try {
        // Update transaction status
        final cancelledAt = DateTime.now().toIso8601String();
        
        // 1. Update transaction status
        await _supabase.from('transactions').update({
          'status': TransactionStatus.cancelled.name,
          'updated_at': cancelledAt,
          'cancellation_reason': reason.name,
          'cancelled_at': cancelledAt,
        }).eq('id', transactionId);

        // 2. Create refund log
        final refundStatus = paymentStatus == PaymentStatus.paid.name 
            ? RefundStatus.pending.name 
            : RefundStatus.processed.name;

        await _refundService.createRefundRequest(
          transactionId: transactionId,
          reason: 'Order cancelled: ${reason.name}',
          notes: '''
            Payment Status: ${paymentStatus}
            Amount: ${totalAmount}
            Cancelled at: ${cancelledAt}
            Student ID: ${studentId}
          ''',
          status: refundStatus, // Pass the appropriate status
        );

        // 3. Update payment status if paid
        if (paymentStatus == PaymentStatus.paid.name) {
          await _supabase.from('transactions').update({
            'payment_status': PaymentStatus.refunded.name,
          }).eq('id', transactionId);
        }

        // 4. Create transaction progress entry
        await _supabase.from('transaction_progress').insert({
          'transaction_id': transactionId,
          'status': TransactionStatus.cancelled.name,
          'notes': 'Order cancelled by customer: ${reason.name}',
          'timestamp': cancelledAt,
        });

        await _supabase.rpc('commit_transaction');
      } catch (e) {
        await _supabase.rpc('rollback_transaction');
        throw e;
      }
    } catch (e) {
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
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            transaction_details!inner (
              id,
              menu_id,
              quantity,
              unit_price,
              subtotal,
              menu:menu!inner ( 
                id,
                food_name,
                price
              )
            )
          ''')
          .eq('student_id', studentId)
          .not('status', 'in',
              ['completed', 'cancelled']) // Updated status values
          .order('created_at', ascending: false);

      // Transform the response to match the expected format
      final transformedResponse = response.map((order) {
        final items = (order['transaction_details'] as List).map((detail) {
          return {
            'id': detail['id'],
            'menu_name': detail['menu']['food_name'],
            'quantity': detail['quantity'],
            'price': detail['unit_price'],
          };
        }).toList();

        return {
          ...order,
          'items': items,
        };
      }).toList();

      return List<Map<String, dynamic>>.from(transformedResponse);
    } catch (e) {
      throw Exception('Failed to load active orders: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getOrderHistory(int studentId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            items:transaction_details( 
              menu:menu(
                id,
                food_name
              ),
              quantity,
              unit_price,
              subtotal
            ),
            refund_logs!refund_logs_transaction_id_fkey(*)
          ''')
          .eq('student_id', studentId)
          .or('status.eq.completed,status.eq.cancelled') // Include both completed and cancelled orders
          .order('created_at', ascending: false);

      // Transform response to match expected format
      return List<Map<String, dynamic>>.from(response.map((order) {
        final items = (order['items'] as List).map((item) => {
          'menu_id': item['menu']['id'],
          'menu_name': item['menu']['food_name'],
          'quantity': item['quantity'],
          'price': item['unit_price'],
        }).toList();

        return {
          ...order,
          'items': items,
        };
      }).toList());
    } catch (e) {
      throw 'Failed to load order history: $e';
    }
  }

  Future<List<Map<String, dynamic>>> getOrderProgressHistory(int transactionId) async {
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
        await _supabase
            .from('transactions')
            .delete()
            .eq('id', transactionId);

        await _supabase.rpc('commit_transaction');
      } catch (e) {
        await _supabase.rpc('rollback_transaction');
        throw e;
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
        throw e;
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
            final details = await _supabase
                .from('transaction_details')
                .select('''
                  *,
                  menu (*),
                  transaction_addon_details (
                    *,
                    addon:food_addons (*)
                  )
                ''')
                .eq('transaction_id', json['id']);
            
            print('Fetched details for transaction ${json['id']}: $details'); // Debug print
            
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

  Future<void> updateOrderStatus(int transactionId, TransactionStatus status) async {
    try {
      Logger.info('Updating order $transactionId to status: ${status.name}');

      await _supabase.from('transactions').update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', transactionId);

      await _supabase.from('transaction_progress').insert({
        'transaction_id': transactionId,
        'status': status.name,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Logger.info('Successfully updated order status');
    } catch (e, stack) {
      Logger.error('Failed to update order status: $e', stack);
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

  Future<Transaction> getOrderDetailsById(int orderId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            transaction_details (
              id,
              menu_id,
              quantity,
              unit_price,
              subtotal,
              notes,
              created_at,
              menu (
                id,
                food_name,
                price,
                photo,
                description
              )
            )
          ''')
          .eq('id', orderId)
          .single();

      print('Fetched order details: $response'); // Debug log
      
      // Add transaction_details to the response for proper parsing
      final transaction = Transaction.fromJson(response);
      print('Parsed transaction details count: ${transaction.details.length}');
      
      return transaction;

    } catch (e) {
      print('Error fetching order details: $e');
      throw Exception('Failed to fetch order details: $e');
    }
  }

  Future<List<TransactionDetail>> getTransactionDetails(int transactionId) async {
    try {
      final response = await _supabase
          .from('transaction_details')
          .select('''
            *,
            menu (*)
          ''')
          .eq('transaction_id', transactionId);

      return (response as List)
          .map((item) => TransactionDetail.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching transaction details: $e');
      return [];
    }
  }
}
