// lib/app.dart
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'controllers/app_controller.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

class HabitBuddyApp extends StatefulWidget {
  const HabitBuddyApp({super.key});

  @override
  State<HabitBuddyApp> createState() => _HabitBuddyAppState();
}

class _HabitBuddyAppState extends State<HabitBuddyApp>
    with WidgetsBindingObserver {
  final AppController _controller = AppController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Habit Buddy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _controller.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}