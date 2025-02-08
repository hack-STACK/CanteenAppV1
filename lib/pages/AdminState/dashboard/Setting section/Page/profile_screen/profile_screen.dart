import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Page/profile_screen/components/profile_info.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Widget/profile_header1.dart';

class ProfileScreen extends StatefulWidget {
  final int standId;
  const ProfileScreen({super.key, required this.standId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _futureStallData;

  @override
  void initState() {
    super.initState();
    _futureStallData = _fetchStallData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _futureStallData = _fetchStallData();
    });
  }

  Future<Map<String, dynamic>> _fetchStallData() async {
    final supabase = Supabase.instance.client;
    final user = FirebaseAuth.instance.currentUser;

    try {
      debugPrint('Starting to fetch stall data...');
      debugPrint(
          'Received Stand ID: ${widget.standId}'); // Fixed: widget.standId

      // First get the Supabase user ID from the users table
      final List<dynamic> userResponse = await supabase
          .from('users')
          .select()
          .eq('firebase_uid', user!.uid)
          .limit(1);

      if (userResponse.isEmpty) {
        throw Exception('User not found in Supabase');
      }

      final supabaseUserId = userResponse.first['id'];
      debugPrint('Supabase User ID: $supabaseUserId');

      // Get stall data using the correct ID
      final List<dynamic> stallResponse = await supabase
          .from('stalls')
          .select()
          .eq('id', widget.standId) // Fixed: widget.standId
          .eq('id_user', supabaseUserId)
          .limit(1);

      debugPrint('Stall Response: $stallResponse');

      if (stallResponse.isEmpty) {
        throw Exception(
            'No stall found with ID: ${widget.standId}'); // Fixed: widget.standId
      }

      final stall = stallResponse.first;
      final Map<String, dynamic> result = {
        'stallId': stall['id'].toString(),
        'stallName': stall['nama_stalls'],
        'ownerName': stall['nama_pemilik'],
        'phone': stall['no_telp'],
        'description': stall['deskripsi'],
        'slot': stall['slot'],
        'email': user.email ?? '',
        'image_url': stall['image_url'], // Add this line
      };

      debugPrint('Processed stall data with image: $result'); // Debug line
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error in _fetchStallData: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'stallId': widget.standId.toString(),
        'stallName': 'Unknown Stall',
        'ownerName': 'Unknown',
        'phone': '-',
        'description': '-',
        'slot': '-',
        'email': user?.email ?? 'No email',
        'image_url': null, // Add this line
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _futureStallData,
          builder: (context, snapshot) {
            debugPrint('FutureBuilder state: ${snapshot.connectionState}');

            if (snapshot.hasError) {
              debugPrint('FutureBuilder error: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!;
            debugPrint('FutureBuilder data: $userData');

            return SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // Enable scrolling for refresh
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.symmetric(vertical: 66),
                child: Column(
                  children: [
                    ProfileHeader(
                      userName: userData['stallName'],
                      email: userData['email'],
                      imageUrl: userData['image_url'], // Add image URL
                    ),
                    const SizedBox(height: 74),
                    ProfileInfo(
                      stallId: userData['stallId'].toString(),
                      userData: userData,
                      onProfileUpdated: _refreshData, // Add refresh callback
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
