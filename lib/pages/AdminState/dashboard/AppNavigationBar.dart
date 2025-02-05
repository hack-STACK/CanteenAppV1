import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/pages/AdminState/dashboard/Addmenu.dart';
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
                    if (standId == null) {
                      print('Stand ID is not available.');
                      return const Center(child: Text('Stand ID is not available.'));
                    }
                    print('Navigating to AdminDashboardScreen with standId: $standId');
                    return AdminDashboardScreen(standId: standId);
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Tracker',
                  name: 'Tracker',
                  builder: (context, state) {
                    if (standId == null) {
                      print('Stand ID is not available.');
                      return const Center(child: Text('Stand ID is not available.'));
                    }
                    print('Navigating to TrackerScreen with standId: $standId');
                    return TrackerScreen(stanId: standId);
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Notifications',
                  name: 'Notifications',
                  builder: (context, state) {
                    if (standId == null) {
                      print('Stand ID is not available.');
                      return const Center(child: Text('Stand ID is not available.'));
                    }
                    print("Navigating to order with stanId: $standId");
                    return OrdersScreen(stanId: standId);
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Settings',
                  name: 'Settings',
                  builder: (context, state) {
                    if (standId == null) {
                      print('Stand ID is not available.');
                      return const Center(child: Text('Stand ID is not available.'));
                    }
                    print('Navigating to SettingsScreen with standId: $standId');
                    return SettingsScreen(standId: standId);
                  },
                ),
              ],
            ),
          ],
        ),
        // Add Menu Route - Outside the StatefulShellRoute
        GoRoute(
          path: '/add-menu',
          name: 'AddMenu',
          parentNavigatorKey: _rootNavigatorKey, // Use root navigator
          builder: (context, state) {
            if (standId == null) {
              return const Center(child: Text('Stand ID is not available.'));
            }
            
            final extra = state.extra as Map<String, dynamic>?;
            final XFile? image = extra?['image'] as XFile?;
            
            return AddMenuScreen(
              standId: standId,
              initialImage: image,
            );
          },
        ),
      ],
    );
  }
}