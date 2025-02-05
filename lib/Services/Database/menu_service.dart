// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:kantin/Models/menu.dart';

// class MenuService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   Future<void> addMenuItem(Menu menu) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       print("User  is not authenticated");
//       return; // Handle the case where the user is not authenticated
//     }

//     try {
//       await FirebaseFirestore.instance.collection('menus').add(menu.toMap());
//       print("Menu item added successfully");
//     } catch (e) {
//       print("Failed to add menu item: $e");
//     }
//   }

//   // Create a new menu item
//   Future<void> createMenu(Menu menu) async {
//     await _db.collection('menus').add(menu.toMap());
//   }

//   // Read all menu items
//   Stream<List<Menu>> getMenus() {
//     return _db.collection('menus').snapshots().map((snapshot) {
//       return snapshot.docs
//           .map((doc) => Menu.fromMap(
//                 doc.id, // Pass the document ID
//                 doc.data(), // Pass the document data
//               ))
//           .toList();
//     });
//   }

//   // Update a menu item
//   Future<void> updateMenu(Menu menu) async {
//     await _db.collection('menus').doc(menu.id).update(menu.toMap());
//   }

//   // Delete a menu item
//   Future<void> deleteMenu(String id) async {
//     await _db.collection('menus').doc(id).delete();
//   }
// }
