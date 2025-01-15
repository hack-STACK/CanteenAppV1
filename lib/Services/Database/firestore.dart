import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to save an order to Firestore
  Future<void> saveOrderToDatabase(String receipt) async {
    try {
      print("Saving order: $receipt"); // Debugging line
      await _db.collection('orders').add({
        'receipt': receipt,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Order saved successfully!"); // Debugging line
    } catch (e) {
      print("Error saving order: $e");
      rethrow; // Rethrow the error for further handling
    }
  }
}
