import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/config/supabase_client.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _client = Supabase.instance.client;

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

  Future<void> updateOrderStatus(int orderId, TransactionStatus newStatus) async {
    try {
      await _client
          .from('transactions')
          .update({'status': newStatus.name, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);
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
      final response = await _client.from('transactions').insert({
        'student_id': studentId,
        'stall_id': stallId,
        'status': TransactionStatus.pending.name,
        'payment_status': PaymentStatus.unpaid.name,
        'order_type': orderType.toJson(),
        'total_amount': totalAmount,
        'notes': notes,
        'delivery_address': deliveryAddress,
      }).select().single();

      final transactionId = response['id'] as int;

      // Insert transaction details
      for (var detail in details) {
        final detailResponse = await _client.from('transaction_details').insert({
          'transaction_id': transactionId,
          'menu_id': detail.menuId,
          'quantity': detail.quantity,
          'unit_price': detail.unitPrice,
          'subtotal': detail.subtotal,
          'notes': detail.notes,
        }).select().single();

        final detailId = detailResponse['id'] as int;

        // Insert addons if any
        for (var addon in detail.addons!) {
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
      await _client
          .from('notifications')
          .insert({
            'order_id': orderId,
            'message': message,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  Future<List<TransactionDetail>> getOrderDetails(String orderId) async {
    final response = await _client
      .from('transaction_details')
      .select('''
        *,
        menu:menu_id(*),
        addons:transaction_addon_details(
          *,
          addon:addon_id(*)
        )
      ''')
      .eq('transaction_id', orderId);
    
    return (response as List)
      .map((detail) => TransactionDetail.fromJson(detail))
      .toList();
  }

  Future<Transaction> getOrderById(String orderId) async {
    final response = await _client
      .from('transactions')
      .select('''
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
      ''')
      .eq('id', orderId)
      .single();
    
    return Transaction.fromJson(response);
  }

  // Future<AppUser.User> getUserById(int userId) async {
  //   final response = await _client
  //     .from('users')
  //     .select('*')
  //     .eq('id', userId)
  //     .single();
    
  //   return AppUser.User.fromJson(response);
  // }

  Future<StudentModel?> getStudentById(int studentId) async {
    final response = await _client
      .from('students')
      .select('*')
      .eq('id', studentId)
      .single();
    
    if (response == null) return null;
    return StudentModel.fromJson(response);
  }

  // Stream<List<Transaction>> getStallOrdersByStatus(int stallId, TransactionStatus status) {
  //   return _client
  //     .from('transactions')
  //     .stream(primaryKey: ['id'])
  //     .eq('stall_id', stallId)
  //     .eq('status', status.name)
  //     .order('created_at')
  //     .map((rows) => rows.map((row) => Transaction.fromJson(row)).toList());
  // }
}