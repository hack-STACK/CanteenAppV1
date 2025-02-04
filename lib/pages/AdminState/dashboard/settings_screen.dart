import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/profile_header1.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/report_section.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/settings_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.standId});
  final int? standId;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 69, 30, 110),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(),
                SizedBox(height: 27),
                SettingsSection(standId: standId),
                SizedBox(height: 48),
                ReportSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
