import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/utils/api_exception.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:kantin/utils/logger.dart'; // Add this import
import 'package:kantin/utils/error_handler.dart' as error_handler; // Use alias

class TransactionService {
  final _supabase = Supabase.instance.client;
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
      // First check current order status
      final orderData = await _supabase
          .from('transactions')
          .select('status, payment_status')
          .eq('id', transactionId)
          .single();

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

      // Begin transaction
      await _supabase.rpc('begin_transaction');

      try {
        // Update transaction status
        await _supabase.from('transactions').update({
          'status': TransactionStatus.cancelled.name,
          'updated_at': DateTime.now().toIso8601String(),
          'cancellation_reason': reason.name,
          'cancelled_at': DateTime.now().toIso8601String(),
        }).eq('id', transactionId);

        // Handle refund if payment was made
        if (paymentStatus == PaymentStatus.paid.name) {
          // Update payment status to refunded
          await _supabase.from('transactions').update({
            'payment_status': PaymentStatus.refunded.name,
          }).eq('id', transactionId);

          // Create refund log
          await _supabase.from('refund_logs').insert({
            'transaction_id': transactionId,
            'reason': reason.name,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'notes': 'Cancellation initiated by customer',
          });
        }

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
          .or('status.eq.completed,status.eq.cancelled') // Updated status values
          .order('created_at', ascending: false)
          .limit(50);

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
      throw Exception('Failed to load order history: ${e.toString()}');
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
}
