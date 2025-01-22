import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/settings_tile.dart';

class ReportSection extends StatelessWidget {
  const ReportSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Bug',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F4F4F),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          ..._buildReportTiles(),
        ],
      ),
    );
  }

  List<Widget> _buildReportTiles() {
    return [
      SettingsTile(
        icon: Icons.bug_report, // Use Flutter's built-in icon
        title: 'Report a Bug',
        onTap: () {
          // Handle report a bug action
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.feedback, // Use Flutter's built-in icon
        title: 'Send Feedback',
        onTap: () {
          // Handle send feedback action
        },
      ),
      const SizedBox(height: 20),
      SettingsTile(
        icon: Icons.coffee, // Use Flutter's built-in icon
        title: 'Buy me some coffee',
        onTap: () {
          // Handle buy coffee action
        },
      ),
    ];
  }
}
