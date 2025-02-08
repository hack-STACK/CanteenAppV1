import 'package:flutter/material.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'widgets/balance_card.dart';
import 'widgets/category_scroll.dart';
import 'widgets/profile_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/top_menu_section.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int? standId;
  const AdminDashboardScreen({super.key, required this.standId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late FoodService foodService;
  late Future<List<Menu>> menuFuture;

  @override
  void initState() {
    super.initState();
    foodService = FoodService();
    menuFuture = _fetchMenus(); // Load menus on startup
  }

  /// Fetch menus and refresh the UI
  Future<List<Menu>> _fetchMenus() async {
    if (widget.standId != null) {
      return await foodService.getMenuByStanId(widget.standId!);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: RefreshIndicator(
        color: Colors.orange, // Warna indikator refresh
        backgroundColor: Colors.white, // Background indikator refresh
        strokeWidth: 3.0, // Ketebalan indikator refresh
        onRefresh: () async {
          setState(() {
            menuFuture = _fetchMenus();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
              bottom: 80), // Agar konten tidak ketutupan navbar
          child: SafeArea(
            child: Container(
              width: screenWidth * 0.9,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  const ProfileHeaderWidget(),
                  const SizedBox(height: 23),
                  const CustomSearchBarWidget(),
                  const SizedBox(height: 10),
                  const CategoryScroll(),
                  const SizedBox(height: 14),
                  BalanceCardWidget(
                    currentBalance: 200000,
                    currencyCode: 'IDR',
                    historicalData: const {
                      'daily': [100, 150, 200, 180, 220, 200, 250],
                      'weekly': [1000, 1200, 1100, 1300, 1250, 1400, 1500],
                      'monthly': [5000, 5500, 6000, 5800, 6200, 6500, 7000],
                      'yearly': [
                        50000,
                        55000,
                        60000,
                        58000,
                        62000,
                        65000,
                        70000
                      ],
                    },
                    primaryColor: const Color(0xFFFF542D),
                    backgroundColor: Colors.white,
                    onCardTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TrackerScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (widget.standId == null)
                    const Text(
                      'Stand ID is missing. Please select a valid stand.',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    )
                  else
                    FutureBuilder<List<Menu>>(
                      future: menuFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Colors.orange, // Warna loading
                                strokeWidth: 4.0, // Ketebalan loading
                              ),
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text(
                            'No menus available.',
                            style: TextStyle(color: Colors.grey),
                          );
                        } else {
                          return TopMenuSection(
                            stanid: widget.standId,
                            foodService: foodService,
                            title: 'Featured Menu',
                            itemCount: snapshot.data!.length,
                            menus: snapshot.data!,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
