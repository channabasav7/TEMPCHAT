import 'package:flutter/material.dart';
import 'navigation/main_navigation_shell.dart';
import 'settings/settings_screen.dart';

export 'settings/settings_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationShell(initialIndex: 4);
  }
}

typedef SettingsContent = SettingsScreen;
