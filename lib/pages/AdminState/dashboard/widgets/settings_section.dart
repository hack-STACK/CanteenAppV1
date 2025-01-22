import 'package:flutter/material.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Auth/login_or_register.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/settings_tile.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({Key? key}) : super(key: key);

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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginOrRegister()),
          (route) => false,
        );
      } catch (e) {
        _showErrorDialog(context, 'Failed to logout: ${e.toString()}');
      }
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    final authService = AuthService();
    final shouldDelete = await _showConfirmationDialog(
      context,
      'Delete Account',
      'Are you sure you want to delete your account? This action cannot be undone.',
    );

    if (shouldDelete == true) {
      try {
        await authService.deleteAccount(); // Call the delete account method

        // Check if the widget is still mounted before navigating
        if (!context.mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginOrRegister()),
          (route) => false,
        );
      } catch (e) {
        if (!context.mounted)
          return; // Check if still mounted before showing dialog
        _showErrorDialog(context, 'Failed to delete account: ${e.toString()}');
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
        icon: Icons.logout,
        title: 'Logout',
        onTap: () => logout(context),
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.delete,
        title: 'Delete Account',
        onTap: () => deleteAccount(context), // Call deleteAccount method
        isDestructive: true,
      ),
    ];
  }
}
