import 'package:flutter/material.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'widgets/balance_card.dart';
import 'widgets/category_scroll.dart';
import 'widgets/profile_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/top_menu_section.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, int? standId});

  @override
  Widget build(BuildContext context) {
    final foodService = FoodService();
    // Get the screen width
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            // Use the screen width for responsive design
            constraints: BoxConstraints(
                maxWidth: screenWidth * 0.9), // 90% of screen width
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
                // Example usage
                BalanceCardWidget(
                  currentBalance: 200000,
                  currencyCode: 'IDR',
                  historicalData: const {
                    'daily': [100, 150, 200, 180, 220, 200, 250],
                    'weekly': [1000, 1200, 1100, 1300, 1250, 1400, 1500],
                    'monthly': [5000, 5500, 6000, 5800, 6200, 6500, 7000],
                    'yearly': [50000, 55000, 60000, 58000, 62000, 65000, 70000],
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

                TopMenuSection(
                  foodService: foodService,
                  title: 'Featured Menu',
                  itemCount: 5,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
