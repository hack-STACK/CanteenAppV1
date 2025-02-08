// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:async';

// class ProfileState extends ChangeNotifier {
//   Map<String, dynamic>? _profileData;
//   bool _isLoading = false;
//   String? _error;
//   Timer? _refreshTimer;

//   Map<String, dynamic>? get profileData => _profileData;
//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   ProfileState() {
//     _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
//       refreshProfile(null);
//     });
//   }

//   Future<void> refreshProfile(String? stallId) async {
//     if (_isLoading || stallId == null) return;

//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final supabase = Supabase.instance.client;
//       final response =
//           await supabase.from('stalls').select().eq('id', stallId).single();

//       _profileData = response;
//       _error = null;
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     super.dispose();
//   }
// }
