import 'package:flutter/material.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/Stats_row.dart';
import 'package:kantin/pages/AdminState/dashboard/widgets/balance_card.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 66, 28, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF542D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Tracker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
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
                  MaterialPageRoute(
                    builder: (context) => TrackerScreen(),
                  );
                },
              ),
              const SizedBox(height: 12),
              const StatsRow(),
              const SizedBox(height: 12),
              BalanceCardWidget(
                currentBalance: 200000,
                currencyCode: 'IDR',
                historicalData: const {
                  'daily': [100, 150, 200, 180, 220, 200, 250],
                  'weekly': [1000, 1200, 1100, 1300, 1250, 1400, 1500],
                  'monthly': [5000, 5500, 6000, 5800, 6200, 6500, 7000],
                  'yearly': [50000, 55000, 60000, 58000, 62000, 65000, 70000],
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
