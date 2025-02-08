import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Widget/profile_header1.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Widget/report_section.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Widget/settings_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatelessWidget {
  final int standId; // Remove nullable type
  const SettingsScreen({super.key, required this.standId});

  Future<Map<String, dynamic>> _fetchUserData() async {
    debugPrint('SettingsScreen - Fetching user data with standId: $standId');
    final supabase = Supabase.instance.client;
    final user = FirebaseAuth.instance.currentUser;

    try {
      final List<dynamic> stallResponse = await supabase
          .from('stalls')
          .select('*') // Select all fields
          .eq('id', standId)
          .limit(1);

      debugPrint('Stall Response: $stallResponse'); // Debug print

      if (stallResponse.isEmpty) {
        throw Exception('No stall found');
      }

      final stall = stallResponse.first;

      return {
        'stallId': stall['id']?.toString() ?? '-',
        'stallName': stall['nama_stalls'] ?? '-',
        'email': user?.email ?? 'No email',
        'ownerName': stall['nama_pemilik'] ?? '-',
        'phone': stall['no_telp'] ?? '-',
        'description': stall['deskripsi'] ?? '-',
        'slot': stall['slot']?.toString() ?? '-',
        'image_url': stall['image_url'], // Add this line
      };
    } catch (e) {
      debugPrint('Error fetching data: $e');
      return {
        'stallId': standId.toString() ?? '-',
        'stallName': 'Unknown Stall',
        'email': user?.email ?? 'No email',
        'ownerName': 'Unknown',
        'phone': '-',
        'description': '-',
        'slot': '-',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context, rootNavigator: true).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFEFEF),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final userData = snapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 69, 30, 110),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ProfileHeader(
                          userName: userData['stallName'],
                          email: userData['email'],
                          imageUrl: userData['image_url'], // Add this line
                        ),
                      ),

                      const SizedBox(height: 27),
                      SettingsSection(
                          standId: standId), // Pass non-null standId
                      const SizedBox(height: 48),
                      const ReportSection(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
