import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Page/Yourstore/my_Store.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Page/profile_screen/profile_screen.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Widget/settings_tile.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class SettingsSection extends StatefulWidget {
  final int? standId;

  const SettingsSection({super.key, required this.standId});

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  void _navigateToProfile(BuildContext context) {
    debugPrint('Navigating to profile with standId: ${widget.standId}');
    if (widget.standId != null) {
      Navigator.of(context, rootNavigator: true).push(
        // Use rootNavigator: true
        MaterialPageRoute(
          fullscreenDialog: true, // Add this
          builder: (context) => ProfileScreen(standId: widget.standId!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stand ID not available')),
      );
    }
  }

  void _navigateToStore(BuildContext context) {
    debugPrint('Navigating to store with userId: ${widget.standId}');
    if (widget.standId != null) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => MyStorePage(userId: widget.standId!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store ID not available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F4F4F),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          ..._buildSettingsTiles(context),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    final authService = AuthService();
    final shouldLogout = await _showConfirmationDialog(
      context,
      'Logout',
      'Are you sure you want to logout?',
    );

    if (shouldLogout == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Perform logout
        await authService.signOut();

        // Close loading indicator
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Navigate to login page
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LoginOrRegister(),
              fullscreenDialog: true,
            ),
            (route) => false,
          );
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e')),
          );
        }
      }
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final authService = AuthService();
    final userService = UserService();
    final stallService = StanService();
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _showErrorDialog(context, 'No user currently signed in.');
      return;
    }

    final shouldDelete = await _showConfirmationDialog(
      context,
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone.',
    );

    if (shouldDelete == true) {
      final password = await _showPasswordDialog(context);

      if (password != null) {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Delete account operations
          final firebaseUid = firebaseUser.uid;
          final user = await userService.getUserByFirebaseUid(firebaseUid);

          if (user == null) {
            throw Exception(
                'Supabase user not found for Firebase UID: $firebaseUid');
          }

          final int supabaseUserId = user.id!;
          await stallService.deleteStallsByUserId(supabaseUserId);
          await userService.deleteUser(supabaseUserId);
          await authService.deleteUserAccount(password);

          // Close loading indicator safely
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Delay navigation to avoid assertion error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => LoginOrRegister(),
                  fullscreenDialog: true,
                ),
                (route) => false,
              );
            }
          });
        } catch (e) {
          // Handle error
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showErrorDialog(
                context, 'Failed to delete account: ${e.toString()}');
          }
        }
      }
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter your password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsTiles(BuildContext context) {
    return [
      SettingsTile(
        icon: Icons.account_circle,
        title: 'Account',
        onTap: () {
          _navigateToProfile(context);
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.notifications,
        title: 'Notification',
        onTap: () {
          // Handle notification action
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.discount,
        title: 'Discount',
        onTap: () {
          // Handle discount action
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.store_mall_directory_outlined,
        title: 'Your store',
        onTap: () => _navigateToStore(context), // Updated navigation
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.logout,
        title: 'Logout',
        onTap: () {
          logout(context);
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.delete,
        title: 'Delete Account',
        onTap: () {
          deleteAccount(context);
        },
      ),
    ];
  }
}
