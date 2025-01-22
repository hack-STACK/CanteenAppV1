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

  static final GoRouter router = GoRouter(
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
                builder: (context, state) => const adminDashboardScreen(),
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
