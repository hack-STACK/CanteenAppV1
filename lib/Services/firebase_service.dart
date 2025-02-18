// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:kantin/Models/menu_model.dart'; // Ensure this import is correct

// class FirebaseService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> addMenu(MenuModel menu) async {
//     await _firestore.collection('menus').add(menu.toMap());
//   }

//   Future<void> updateMenu(String id, MenuModel menu) async {
//     await _firestore.collection('menus').doc(id).update(menu.toMap());
//   }

//   Future<void> deleteMenu(String id) async {
//     await _firestore.collection('menus').doc(id).delete();
//   }

//   Future<List<MenuModel>> getMenus() async {
//     final snapshot = await _firestore.collection('menus').get();
//     return snapshot.docs.map((doc) => MenuModel.fromMap(doc.data())).toList();
//   }

//   Future<void> incrementMenuOrderCount(String id) async {
//     await _firestore.collection('menus').doc(id).update({
//       'orderCount': FieldValue.increment(1),
//     });
//   }

//   Future<void> decrementMenuOrderCount(String id) async {
//     await _firestore.collection('menus').doc(id).update({
//       'orderCount': FieldValue.increment(-1),
//     });
//   }
// }
