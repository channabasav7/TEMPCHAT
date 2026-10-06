import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../state/app_state.dart';
import 'onboarding/landing_screen.dart';

export 'onboarding/landing_screen.dart';
export 'onboarding/username_setup_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'TempChat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: const LandingScreen(),
          );
        },
      ),
    );
  }
}
