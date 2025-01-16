import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kantin/Models/menu.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new menu item
  Future<void> createMenu(Menu menu) async {
    await _db.collection('menus').add(menu.toMap());
  }

  // Read all menu items
  Stream<List<Menu>> getMenus() {
    return _db.collection('menus').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Menu.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Update a menu item
  Future<void> updateMenu(Menu menu) async {
    await _db.collection('menus').doc(menu.id).update(menu.toMap());
  }

  // Delete a menu item
  Future<void> deleteMenu(String id) async {
    await _db.collection('menus').doc(id).delete();
  }
}