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
    // Method to save a canteen slot to Firestore
  Future<void> saveCanteenSlot(String adminId, String slotName) async {
    try {
      print("Saving canteen slot: $slotName for admin: $adminId"); // Debugging line
      await _db.collection('canteen_slots').add({
        'adminId': adminId,
        'slotName': slotName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Canteen slot saved successfully!"); // Debugging line
    } catch (e) {
      print("Error saving canteen slot: $e");
      rethrow; // Rethrow the error for further handling
    }
  }
    Future<List<String>> getCanteenSlots() async {
    try {
      QuerySnapshot snapshot = await _db.collection('canteen_slots').get();
      return snapshot.docs.map((doc) => doc['slotName'] as String).toList();
    } catch (e) {
      print("Error fetching canteen slots: $e");
      return []; // Return an empty list on error
    }
  }
    // Method to check if a canteen name already exists
  Future<bool> doesCanteenNameExist(String canteenName) async {
    try {
      QuerySnapshot snapshot = await _db.collection('canteen_slots')
          .where('slotName', isEqualTo: canteenName)
          .get();
      return snapshot.docs.isNotEmpty; // Return true if any documents found
    } catch (e) {
      print("Error checking canteen name: $e");
      return false; // Return false on error
    }
  }
  Future<String?> getCanteenNameByUid(String adminUid) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('canteen_slots')
        .where('adminUid', isEqualTo: adminUid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first['canteenName'] as String?;
    } else {
      print('Canteen name not found for this admin.');
      return null;
    }
  } catch (e) {
    print('Failed to fetch canteen name: $e');
    return null;
  }
}

}
