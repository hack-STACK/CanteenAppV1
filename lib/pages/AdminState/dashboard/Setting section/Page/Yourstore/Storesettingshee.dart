import 'package:flutter/material.dart';

class StoreSettingsSheet extends StatelessWidget {
  final VoidCallback onEditStore;
  final VoidCallback onChangeCoverPhoto;
  final VoidCallback onDeleteStore;

  const StoreSettingsSheet({
    Key? key,
    required this.onEditStore,
    required this.onChangeCoverPhoto,
    required this.onDeleteStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildSettingsItem(
            context,
            icon: Icons.edit,
            title: 'Edit Store',
            onTap: onEditStore,
          ),
          _buildSettingsItem(
            context,
            icon: Icons.photo_library,
            title: 'Change Cover Photo',
            onTap: onChangeCoverPhoto,
          ),
          _buildSettingsItem(
            context,
            icon: Icons.delete,
            title: 'Delete Store',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: onDeleteStore,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading:
          Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style:
            Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      onTap: onTap,
    );
  }
}
