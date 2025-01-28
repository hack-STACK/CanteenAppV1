import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin/pages/AdminState/dashboard/DashboardScreen.dart';
import 'package:kantin/pages/AdminState/dashboard/Order_page.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'package:kantin/pages/AdminState/dashboard/Homepage.dart';
import 'package:kantin/pages/AdminState/dashboard/settings_screen.dart';

class AppNavigationBar {
  AppNavigationBar._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter configureRouter(int? standId) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/Home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return DashboardScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Home',
                  name: 'Home',
                  builder: (context, state) {
                    // Handle null standId case
                    if (standId == null) {
                      print('Stand ID is not available.'); // Debugging print
                      return const Center(
                          child: Text('Stand ID is not available.'));
                    }
                    print(
                        'Navigating to AdminDashboardScreen with standId: $standId'); // Debugging print
                    return AdminDashboardScreen(
                        standId: standId); // Pass standId here
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Tracker',
                  name: 'Tracker',
                  builder: (context, state) => const TrackerScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Notifications',
                  name: 'Notifications',
                  builder: (context, state) => const OrdersScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Settings',
                  name: 'Settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
