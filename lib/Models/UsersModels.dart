import 'package:crypto/crypto.dart';
import 'dart:convert';

class UserModel {
  final int? id; // Unique identifier for each user (nullable for new users)
  final String email; // Username for the user
  final String password; // Password for the user (hashed)
  final String role; // Role of the user (e.g., 'admin_stalls' or 'student')
  final String firebaseUid; // Firebase UID for the user
  final bool
      hasCompletedForm; // Indicates if the user has completed the profile form
  final DateTime? createdAt; // Timestamp for when the user was created

  UserModel({
    this.id,
    required this.email,
    required this.password,
    required this.role,
    required this.firebaseUid,
    this.hasCompletedForm = false, // Default to false
    this.createdAt,
  });

  // Convert a UserModel instance to a Map for database operations.
  // Only include 'id' if it is not null.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'Email': email,
      'password': password, // Ensure to hash passwords before storing
      'role': role,
      'firebase_uid': firebaseUid, // Include Firebase UID
      'has_completed_Profile': hasCompletedForm, // Profile completion status
      'created_at':
          createdAt?.toIso8601String(), // Convert DateTime to ISO string
    };

    // Only include id if it's not null (for updates).
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Create a UserModel instance from a Map (e.g., from a database query)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      email: map['Email'],
      password: map['password'],
      role: map['role'],
      firebaseUid: map['firebase_uid'], // Ensure correct key for Firebase UID
      hasCompletedForm:
          map['has_completed_Profile'] ?? false, // Default to false
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']) // Parse ISO string to DateTime
          : null,
    );
  }

  // Add fromJson factory constructor as alias to fromMap
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  // Hash the password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Return the hashed password
  }

  // Factory constructor for creating a UserModel without an ID (for new users)
  factory UserModel.withoutId({
    required String username,
    required String password,
    required String role,
    required String firebaseUid,
    bool hasCompletedForm = false,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: null, // ID is null for new users
      email: username,
      password: hashPassword(password), // Hash the password before storing
      role: role,
      firebaseUid: firebaseUid,
      hasCompletedForm: hasCompletedForm,
      createdAt: createdAt,
    );
  }

  // You can also add a toJson method as alias to toMap
  Map<String, dynamic> toJson() => toMap();
}
