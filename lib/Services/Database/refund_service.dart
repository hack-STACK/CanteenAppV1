import 'package:supabase_flutter/supabase_flutter.dart';

enum RefundStatus {
  pending,
  approved,
  rejected,
  processed
}

class RefundService {
  final _supabase = Supabase.instance.client;

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
        'status': status ?? RefundStatus.pending.name, // Use provided status or default to pending
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

  Future<List<Map<String, dynamic>>> getRefundsByTransactionId(int transactionId) async {
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

  Future<List<Map<String, dynamic>>> getRefundsByStatus(RefundStatus status) async {
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

  Stream<List<Map<String, dynamic>>> streamRefundsByStatus(RefundStatus status) {
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
      final response = await _supabase
          .from('refund_logs')
          .select('status');  // Remove throwOnError

      if (response == null) {
        throw Exception('Failed to fetch refund statistics');
      }

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
}