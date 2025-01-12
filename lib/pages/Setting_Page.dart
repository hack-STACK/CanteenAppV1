import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kantin/Themes/theme_providers.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Use primary color
      ),
      backgroundColor:
          Theme.of(context).colorScheme.surface, // Use background color
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surface, // Use surface color for the container
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2), // Shadow position
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            padding: const EdgeInsets.all(25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dark Mode",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface, // Use onSurface color for text
                  ),
                ),
                CupertinoSwitch(
                  value: Provider.of<ThemeProviders>(context, listen: false)
                      .isDarkMode,
                  onChanged: (value) {
                    Provider.of<ThemeProviders>(context, listen: false)
                        .toggleTheme();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
