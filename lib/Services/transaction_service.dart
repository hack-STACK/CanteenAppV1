// import 'package:kantin/Services/Database/studentService.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:kantin/Models/transaction_model.dart';
// import 'package:kantin/Models/Restaurant.dart';
// import 'package:kantin/models/enums/transaction_enums.dart'; // Add this import
// import 'package:kantin/Models/student_models.dart';

// class TransactionService {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   final StudentService _studentService = StudentService();

//   Future<int> createTransaction({
//     required int studentId,
//     required int stallId,
//     required double totalAmount,
//     required String deliveryAddress,
//     String? notes,
//     List<CartItem>? items,
//   }) async {
//     try {
//       final transactionData = {
//         'student_id': studentId,
//         'stall_id': stallId,
//         'total_amount': totalAmount,
//         'delivery_address': deliveryAddress,
//         'notes': notes,
//         'status': TransactionStatus.pending.name,
//         'payment_status': PaymentStatus.unpaid.name,
//       };

//       final response = await _supabase
//           .from('transactions')
//           .insert(transactionData)
//           .select()
//           .single();

//       final transactionId = response['id'];

//       if (items != null) {
//         await _insertTransactionDetails(transactionId, items);
//       }

//       return transactionId;
//     } catch (e) {
//       throw Exception('Failed to create transaction: $e');
//     }
//   }

//   // Insert transaction details and addons
//   Future<void> _insertTransactionDetails(int transactionId, List<CartItem> items) async {
//     try {
//       for (var item in items) {
//         // First insert the transaction detail
//         final detailResponse = await _supabase
//             .from('transaction_details')
//             .insert({
//               'transaction_id': transactionId,
//               'menu_id': item.menu.id,
//               'quantity': item.quantity,
//               'unit_price': item.menu.price,
//               'subtotal': item.menu.price * item.quantity,
//               'notes': item.note,
//             })
//             .select()
//             .single();

//         // Then insert addons with the transaction_detail_id
//         if (item.selectedAddons.isNotEmpty) {
//           final addonDetails = item.selectedAddons.map((addon) => {
//             'transaction_detail_id': detailResponse['id'],
//             'addon_id': addon.id,
//             'quantity': item.quantity,
//             'unit_price': addon.price,
//             'subtotal': addon.price * item.quantity,
//           }).toList();

//           await _supabase.from('transaction_addon_details').insert(addonDetails);
//         }
//       }
//     } catch (e) {
//       print('Error inserting transaction details: $e');
//       throw Exception('Failed to create transaction details: $e');
//     }
//   }

//   Stream<List<Transaction>> getStudentTransactions(int studentId) {
//     return _supabase
//         .from('transactions')
//         .stream(primaryKey: ['id'])
//         .eq('student_id', studentId)
//         .order('created_at', ascending: false)
//         .map((list) => list.map((item) => Transaction.fromJson(item)).toList());
//   }

//   Stream<List<Transaction>> getStallTransactions(int stallId) {
//     return _supabase
//         .from('transactions')
//         .stream(primaryKey: ['id'])
//         .eq('stall_id', stallId)
//         .order('created_at', ascending: false)
//         .asyncMap((response) async {
//           print('Raw transaction response: $response'); // Debug print
          
//           final List<Transaction> transactions = [];
          
//           for (final transaction in response) {
//             // Fetch transaction details separately
//             final details = await _supabase
//                 .from('transaction_details')
//                 .select('''
//                   *,
//                   menu:menu(*),
//                   transaction_addon_details(
//                     *,
//                     addon:food_addons(*)
//                   )
//                 ''')
//                 .eq('transaction_id', transaction['id']);
            
//             print('Fetched details for transaction ${transaction['id']}: $details'); // Debug print
            
//             // Combine transaction with its details
//             final fullTransaction = {
//               ...transaction,
//               'transaction_details': details,
//             };
            
//             transactions.add(Transaction.fromJson(fullTransaction));
//           }
          
//           return transactions;
//         });
//   }

//   Stream<List<Transaction>> subscribeToNewOrders(int stallId) {
//     return _supabase
//         .from('transactions')
//         .select()
//         .eq('stall_id', stallId)
//         .eq('status', TransactionStatus.pending.name)
//         .order('created_at', ascending: false)
//         .asStream()
//         .map((data) => data.map((item) => Transaction.fromJson(item)).toList());
//   }

//   Future<void> updateTransactionStatus(
//       int transactionId, TransactionStatus status) async {
//     await _supabase.from('transactions').update({
//       'status': status.name,
//       'updated_at': DateTime.now().toIso8601String(),
//     }).eq('id', transactionId);
//   }

//   Future<void> updateOrderStatus(
//       int transactionId, TransactionStatus status) async {
//     await _supabase.from('transactions').update({
//       'status': status.name,
//       'updated_at': DateTime.now().toIso8601String(),
//     }).eq('id', transactionId);
//   }

//   Future<void> updatePayment(
//     int transactionId,
//     PaymentStatus status,
//     PaymentMethod method,
//   ) async {
//     await _supabase.from('transactions').update({
//       'payment_status': status.name,
//       'payment_method': method.name,
//       'updated_at': DateTime.now().toIso8601String(),
//     }).eq('id', transactionId);
//   }

//   Future<void> updateTransactionPayment(
//     int transactionId, {
//     required PaymentStatus paymentStatus,
//     required PaymentMethod paymentMethod,
//   }) async {
//     try {
//       await _supabase.from('transactions').update({
//         'payment_status': paymentStatus.name,
//         'payment_method': paymentMethod.name,
//         'updated_at': DateTime.now().toIso8601String(),
//       }).eq('id', transactionId);
//     } catch (e) {
//       throw Exception('Failed to update payment: $e');
//     }
//   }

//   Future<void> updateEstimatedDeliveryTime(
//     int transactionId,
//     DateTime estimatedTime,
//   ) async {
//     await _supabase.from('transactions').update({
//       'estimated_delivery_time': estimatedTime.toIso8601String(),
//       'updated_at': DateTime.now().toIso8601String(),
//     }).eq('id', transactionId);
//   }

//   Future<Transaction> getTransactionById(int transactionId) async {
//     final response = await _supabase.from('transactions').select('''
//           *,
//           details:transaction_details(
//             *,
//             menu:menus(*),
//             addons:transaction_addon_details(
//               *,
//               addon:addons(*)
//             )
//           )
//         ''').eq('id', transactionId).single();

//     return Transaction.fromJson(response);
//   }

//   Future<StudentModel?> getStudentDetails(int studentId) async {
//     return await _studentService.getStudentById(studentId);
//   }
// }