import 'package:kantin/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RefundStatus { pending, approved, rejected, processed }

class RefundService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  // Timeout constants
  static const pendingTimeout = Duration(minutes: 5);
  static const confirmedTimeout = Duration(minutes: 15);
  static const cookingTimeout = Duration(minutes: 30);

  Future<void> createRefundRequest({
    required int transactionId,
    required String reason,
    String? notes,
    String? status, // Add status parameter
  }) async {
    try {
      await _supabase.from('refund_logs').insert({
        'transaction_id': transactionId,
        'reason': reason,
        'status': status ??
            RefundStatus
                .pending.name, // Use provided status or default to pending
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create refund request: $e');
    }
  }

  Future<void> updateRefundStatus({
    required int refundId,
    required RefundStatus status,
    String? notes,
  }) async {
    try {
      await _supabase.from('refund_logs').update({
        'status': status.name,
        if (notes != null) 'notes': notes,
      }).eq('id', refundId);
    } catch (e) {
      throw Exception('Failed to update refund status: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRefundsByTransactionId(
      int transactionId) async {
    try {
      final response = await _supabase
          .from('refund_logs')
          .select()
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get refund history: $e');
    }
  }

  Future<Map<String, dynamic>?> getRefundById(int refundId) async {
    try {
      final response = await _supabase
          .from('refund_logs')
          .select()
          .eq('id', refundId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to get refund details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRefundsByStatus(
      RefundStatus status) async {
    try {
      final response = await _supabase
          .from('refund_logs')
          .select()
          .eq('status', status.name)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get refunds by status: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamRefundsByStatus(
      RefundStatus status) {
    return _supabase
        .from('refund_logs')
        .stream(primaryKey: ['id'])
        .eq('status', status.name)
        .order('created_at', ascending: false)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  Future<void> deleteRefund(int refundId) async {
    try {
      await _supabase.from('refund_logs').delete().eq('id', refundId);
    } catch (e) {
      throw Exception('Failed to delete refund record: $e');
    }
  }

  Future<Map<String, int>> getRefundStatistics() async {
    try {
      final response = await _supabase.from('refund_logs').select('status');

      final stats = {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'processed': 0,
      };

      for (final record in response) {
        final status = record['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get refund statistics: $e');
    }
  }

  Future<void> checkAndProcessAutomaticRefunds() async {
    try {
      // First, get all cancelled orders that might need refunds
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('status', 'cancelled')
          .eq('payment_status', 'paid')
          .not('refund_processed', 'neq',
              null) // Fixed: use not + neq to check for NULL
          .order('created_at');

      if (response == null || (response as List).isEmpty) {
        return; // No refunds to process
      }

      for (final order in response) {
        try {
          await _processAutomaticRefund(order['id']);
        } catch (e) {
          _logger.error('Failed to process automatic refund', e);
          // Continue with next order even if one fails
          continue;
        }
      }
    } catch (e) {
      _logger.error('Error processing automatic refunds', e);
      throw Exception('Failed to process automatic refunds: $e');
    }
  }

  Future<void> _processAutomaticRefund(int transactionId) async {
    try {
      // Start a transaction to ensure data consistency
      await _supabase.rpc('process_refund', params: {
        'transaction_id': transactionId,
        'reason': 'Automatic refund for cancelled order',
        'amount': null, // Will use full amount from transaction
      });
    } catch (e) {
      _logger.error('Failed to process automatic refund', e);
      throw Exception('Failed to process automatic refund: $e');
    }
  }

  Duration _getTimeoutForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingTimeout;
      case 'confirmed':
        return confirmedTimeout;
      case 'cooking':
        return cookingTimeout;
      default:
        return pendingTimeout;
    }
  }
}
