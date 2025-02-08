import 'package:flutter/material.dart';
import '../edit_profile_screen.dart';

class ProfileInfo extends StatelessWidget {
  final String stallId;
  final Map<String, dynamic>? userData;
  final Function()? onProfileUpdated;

  const ProfileInfo({
    super.key,
    required this.stallId,
    this.userData,
    this.onProfileUpdated,
  });

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => EditProfileScreen(
          initialData: userData ?? {},
          stallId: stallId,
        ),
      ),
    );

    if (result == true && onProfileUpdated != null) {
      onProfileUpdated!(); // Call refresh when returning from edit screen
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add debug prints to check incoming data
    debugPrint('ProfileInfo - Stall ID: $stallId');
    debugPrint('ProfileInfo - UserData: $userData');

    if (userData == null || userData!.isEmpty) {
      debugPrint('ProfileInfo - No data available');
      return const Center(child: Text('No profile data available'));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEdit(context),
                ),
              ],
            ),
            const Divider(),
            _buildInfoTile(Icons.store, 'Stall ID', stallId),
            _buildInfoTile(Icons.person, 'Owner Name',
                userData?['ownerName']?.toString() ?? 'N/A'),
            _buildInfoTile(
                Icons.phone, 'Phone', userData?['phone']?.toString() ?? 'N/A'),
            _buildInfoTile(Icons.description, 'Description',
                userData?['description']?.toString() ?? 'N/A'),
            _buildInfoTile(
                Icons.place, 'Slot', userData?['slot']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    // Add debug print for each tile
    debugPrint('Building InfoTile - $title: $value');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
