import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserModel {
  final int? id; // Unique identifier for each user, optional for new users
  final String username; // Username for the user
  final String password; // Password for the user (consider hashing this)
  final String role; // Role of the user (admin_stalls or student)

  UserModel({
    this.id, // Make id optional for new users
    required this.username,
    required this.password,
    required this.role,
  });

  // Convert a UserModel instance to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password, // Ensure to hash passwords before storing
      'role': role,
    };
  }

  // Create a UserModel instance from a Map (e.g., from a database query)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
    );
  }

  // Hash the password using SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Return the hashed password
  }

  // Factory constructor for creating a UserModel without an ID
  factory UserModel.withoutId({
    required String username,
    required String password,
    required String role,
  }) {
    return UserModel(
      username: username,
      password: password, // Hash the password before passing it
      role: role,
    );
  }
}
