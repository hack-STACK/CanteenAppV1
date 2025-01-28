import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData? icon; // Change from String? to IconData?
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon,
                    size: 24,
                    color: isDestructive
                        ? Colors.red
                        : Colors.black), // Use Flutter's Icon
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDestructive ? Colors.red : Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
