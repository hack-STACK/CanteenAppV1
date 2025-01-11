import 'package:flutter/material.dart';
import 'package:kantin/Component/my_drawer_tile.dart';
import 'package:kantin/pages/Setting_Page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context)
          .colorScheme
          .surface, // Use surface color for the drawer background
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Icon(
              Icons.lock_clock_rounded,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary, // Use primary color for the icon
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Divider(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface, // Use onSurface color for the divider
            ),
          ),
          MyDrawerTile(
            text: "H O M E",
            icon: Icons.home,
            onTap: () => Navigator.pop(context),
          ),
          MyDrawerTile(
            text: "S E T T I N G",
            icon: Icons.settings,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
          const Spacer(),
          MyDrawerTile(
            text: "L O G O U T",
            icon: Icons.logout,
            onTap: () {
              // Handle logout logic here
            },
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
