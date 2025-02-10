import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/pages/AdminState/dashboard/Addmenu.dart';
import 'package:kantin/pages/AdminState/dashboard/DashboardScreen.dart';
import 'package:kantin/pages/AdminState/dashboard/Order_page.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'package:kantin/pages/AdminState/dashboard/Homepage.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/settings_screen.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting section/Page/Yourstore/my_Store.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting section/Page/profile_screen/profile_screen.dart';

class AppNavigationBar extends ChangeNotifier {
  AppNavigationBar._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();
  static final AppNavigationBar _instance = AppNavigationBar._();

  void refresh() {
    notifyListeners();
  }

  static GoRouter configureRouter(int? standId) {
    Widget handleNullStandId(BuildContext context, Widget destination) {
      if (standId == null) {
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_mall_directory, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Store not available',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please complete your store setup first',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
      return destination;
    }

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/Home',
      refreshListenable: _instance,
      routes: [
        // Standalone routes (without bottom nav bar)
        GoRoute(
          path: '/my-store/:userId',
          name: 'MyStore',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final userId = int.parse(state.pathParameters['userId'] ?? '0');
            return MyStorePage(userId: userId);
          },
        ),
        GoRoute(
          path: '/add-menu',
          name: 'AddMenu',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            if (standId == null) {
              return const Scaffold(
                body: Center(
                    child: Text('Store setup required to add menu items')),
              );
            }
            final extra = state.extra as Map<String, dynamic>?;
            final XFile? image = extra?['image'] as XFile?;
            return AddMenuScreen(standId: standId, initialImage: image);
          },
        ),
        GoRoute(
          path: '/profile/:standId',
          name: 'Profile',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final standId = int.parse(state.pathParameters['standId'] ?? '0');
            return ProfileScreen(standId: standId);
          },
        ),

        // Main navigation with bottom nav bar
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
                  builder: (context, state) =>
                      AdminDashboardScreen(standId: standId),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Tracker',
                  name: 'Tracker',
                  builder: (context, state) => handleNullStandId(
                      context, TrackerScreen(stanId: standId ?? 0)),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Notifications',
                  name: 'Notifications',
                  builder: (context, state) => handleNullStandId(
                      context, OrdersScreen(stanId: standId ?? 0)),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/Settings',
                  name: 'Settings',
                  builder: (context, state) => handleNullStandId(
                      context, SettingsScreen(standId: standId ?? 0)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static int _calculateSelectedIndex(GoRouterState state) {
    final String location = state.uri.path;
    if (location.startsWith('/Home')) return 0;
    if (location.startsWith('/Tracker')) return 1;
    if (location.startsWith('/Notifications')) return 2;
    if (location.startsWith('/Settings')) return 3;
    return 0;
  }

  static void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/Home');
        break;
      case 1:
        context.go('/Tracker');
        break;
      case 2:
        context.go('/Notifications');
        break;
      case 3:
        context.go('/Settings');
        break;
    }
  }
}
