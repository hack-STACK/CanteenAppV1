import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleProvider with ChangeNotifier {
  String _role;

  // Constructor with a default role
  RoleProvider({String initialRole = 'student'}) : _role = initialRole;

  // Getter for the current role
  String get role => _role;

  // Method to set the role, ensuring it can only be 'admin_stalls' or 'student'
  Future<void> setRole(String newRole) async {
    if (newRole == 'admin_stalls' || newRole == 'student') {
      _role = newRole;
      notifyListeners(); // Notify listeners about the change
      await _saveRoleToPreferences(newRole); // Save role to local storage
    } else {
      // Handle invalid role gracefully
      print(
          'Invalid role: $newRole. Only "admin_stalls" or "student" are allowed.');
    }
  }

  // Method to check if the current role is admin
  bool isAdmin() => _role == 'admin_stalls';

  // Method to check if the current role is student
  bool isStudent() => _role == 'student';

  // Method to save the role to SharedPreferences
  Future<void> _saveRoleToPreferences(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
  }

  // Method to load the role from SharedPreferences
  Future<void> loadRoleFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString('userRole') ?? 'student'; // Default to 'student'
    notifyListeners(); // Notify listeners about the change
  }
}
