import 'package:flutter/material.dart';

class RoleProvider with ChangeNotifier {
  String _role = 'admin'; // Default role

  String get role => _role;

  void setRole(String newRole) {
    _role = newRole;
    notifyListeners(); // Notify listeners to rebuild widgets that depend on this value
  }
}
