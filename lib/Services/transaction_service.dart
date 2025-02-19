import 'package:kantin/Services/Database/studentService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/Models/transaction_model.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Models/order_status.dart'; // Import OrderStatus
import 'package:kantin/Models/student_models.dart'; // Import StudentModels

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StudentService _studentService = StudentService(); // Initialize StudentService

  // Create a new transaction
  Future<int> createTransaction({
    required int studentId,
    required int stallId,
    required double totalAmount,
    required String deliveryAddress,
    String? notes,
    List<CartItem>? items,
  }) async {
    try {
      final transactionData = {
        'student_id': studentId,
        'stall_id': stallId,
        'total_amount': totalAmount,
        'delivery_address': deliveryAddress,
        'notes': notes,
        'status': TransactionStatus.pending.toString().split('.').last.toLowerCase(),
        'payment_status': PaymentStatus.unpaid.toString().split('.').last.toLowerCase(),
      };

      final response = await _supabase
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      final transactionId = response['id'];

      if (items != null) {
        await _insertTransactionDetails(transactionId, items);
      }

      return transactionId;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Insert transaction details and addons
  Future<void> _insertTransactionDetails(int transactionId, List<CartItem> items) async {
    for (var item in items) {
      final detailData = {
        'transaction_id': transactionId,
        'menu_id': item.menu.id,
        'quantity': item.quantity,
        'unit_price': item.menu.price,
        'subtotal': item.menu.price * item.quantity,
        'notes': item.note,
        'created_at': DateTime.now().toIso8601String(),
      };

      final detailResponse = await _supabase
          .from('transaction_details')
          .insert(detailData)
          .select()
          .single();

      if (item.selectedAddons.isNotEmpty) {
        final addonDetails = item.selectedAddons.map((addon) => {
          'transaction_detail_id': detailResponse['id'],
          'addon_id': addon.id,
          'quantity': 1, // You might want to add quantity for addons in your CartItem
          'unit_price': addon.price,
          'subtotal': addon.price, // subtotal = unit_price * quantity
          'created_at': DateTime.now().toIso8601String(),
        }).toList();

        await _supabase
            .from('transaction_addon_details')
            .insert(addonDetails);
      }
    }
  }

  // Get student's transactions
  Stream<List<Transaction>> getStudentTransactions(int studentId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .map((list) => list
            .map((item) => Transaction.fromMap(item))
            .toList());
  }

  // Get stall's transactions
  Stream<List<Transaction>> getStallTransactions(int stallId) {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('stall_id', stallId)
        .order('created_at', ascending: false)
        .map((list) => list
            .map((item) => Transaction.fromMap(item))
            .toList());
  }

  // Listen for new orders for a stall
  Stream<List<Transaction>> subscribeToNewOrders(int stallId) {
    return _supabase
        .from('transactions')
        .select()
        .eq('stall_id', stallId)
        .eq('status', TransactionStatus.pending.toString().split('.').last.toLowerCase())
        .order('created_at', ascending: false)
        .asStream()
        .map((data) => data.map((item) => Transaction.fromMap(item)).toList());
  }

  // Update transaction status
  Future<void> updateTransactionStatus(int transactionId, TransactionStatus status) async {
    await _supabase
        .from('transactions')
        .update({
          'status': status.toString().split('.').last.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }

  // Update order status
  Future<void> updateOrderStatus(int transactionId, OrderStatus status) async {
    await _supabase
        .from('transactions')
        .update({
          'status': status.toString().split('.').last.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }

  // Update payment status and method
  Future<void> updatePayment(
    int transactionId,
    PaymentStatus status,
    PaymentMethod method,
  ) async {
    await _supabase
        .from('transactions')
        .update({
          'payment_status': status.toString().split('.').last.toLowerCase(),
          'payment_method': method.toString().split('.').last.toLowerCase(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }

  // Update estimated delivery time
  Future<void> updateEstimatedDeliveryTime(
    int transactionId,
    DateTime estimatedTime,
  ) async {
    await _supabase
        .from('transactions')
        .update({
          'estimated_delivery_time': estimatedTime.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }

  // Get a single transaction with details
  Future<Transaction> getTransactionById(int transactionId) async {
    final response = await _supabase
        .from('transactions')
        .select('''
          *,
          details:transaction_details(
            *,
            menu:menus(*),
            addons:transaction_addon_details(
              *,
              addon:addons(*)
            )
          )
        ''')
        .eq('id', transactionId)
        .single();

    return Transaction.fromMap(response);
  }

  // Get student details for a transaction
  Future<StudentModel?> getStudentDetails(int studentId) async {
    return await _studentService.getStudentById(studentId);
  }
}