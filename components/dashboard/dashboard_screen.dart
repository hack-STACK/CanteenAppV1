import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/profile_header.dart';
import 'widgets/search_bar.dart';
import 'widgets/category_scroll.dart';
import 'widgets/balance_card.dart';
import 'widgets/top_menu_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            margin: const EdgeInsets.symmetric(horizontal: auto),
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: const [
                ProfileHeader(),
                SizedBox(height: 23),
                SearchBar(),
                SizedBox(height: 10),
                CategoryScroll(),
                SizedBox(height: 14),
                BalanceCard(),
                SizedBox(height: 20),
                TopMenuSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}