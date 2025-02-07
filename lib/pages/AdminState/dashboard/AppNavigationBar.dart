import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kantin/pages/AdminState/dashboard/Addmenu.dart';
import 'package:kantin/pages/AdminState/dashboard/DashboardScreen.dart';
import 'package:kantin/pages/AdminState/dashboard/Order_page.dart';
import 'package:kantin/pages/AdminState/dashboard/TrackerPage.dart';
import 'package:kantin/pages/AdminState/dashboard/Homepage.dart';
import 'package:kantin/pages/AdminState/dashboard/settings_screen.dart';

class AppNavigationBar extends ChangeNotifier {
  AppNavigationBar._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final AppNavigationBar _instance = AppNavigationBar._();

  /// Method to trigger refresh
  void refresh() {
    notifyListeners(); // Notify GoRouter to refresh pages
  }

  static GoRouter configureRouter(int? standId) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/Home',
      refreshListenable: _instance, // Enables refresh when notifyListeners() is called
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
                      return const Center(child: Text('Stand ID is not available.'));
                    }
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
                      return const Center(child: Text('Stand ID is not available.'));
                    }
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
                      return const Center(child: Text('Stand ID is not available.'));
                    }
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
                      return const Center(child: Text('Stand ID is not available.'));
                    }
                    return SettingsScreen(standId: standId);
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/add-menu',
          name: 'AddMenu',
          parentNavigatorKey: _rootNavigatorKey,
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
