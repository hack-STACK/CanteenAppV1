import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/settings_tile.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kantin/pages/User/login_page.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key});

  @override
  _SettingsSectionState createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
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
        await authService.signOut();
        print("User signed out successfully."); // Debug statement

        // Navigate to LoginOrRegister after logout
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginOrRegister()),
          );
        }
      } catch (e) {
        _showErrorDialog(context, 'Failed to logout: ${e.toString()}');
      }
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final authService = AuthService();
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

    // Check if a user is signed in before attempting to delete the account
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
      try {
        await authService.deleteAccount(); // Call the delete account method

        // Navigate to LoginPage after account deletion
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog(context, 'Failed to delete account: ${e.toString()}');
        }
      }
    }
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
          // Handle account action
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.notifications,
        title: 'Notification',
        onTap: () {
          // Handle notification action
        },),
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