// import 'package:flutter/material.dart';

// class RoleProvider with ChangeNotifier {
//   String _role;

//   // Constructor with a default role
//   RoleProvider({String initialRole = 'student'}) : _role = initialRole;

//   String get role => _role;

//   // Method to set the role, ensuring it can only be 'admin' or 'student'
//   void setRole(String newRole) {
//     if (newRole == 'admin' || newRole == 'student') {
//       _role = newRole;
//       notifyListeners();
//     } else {
//       throw Exception(
//           'Invalid role: $newRole. Only "admin" or "student" are allowed.');
//     }
//   }
// }
