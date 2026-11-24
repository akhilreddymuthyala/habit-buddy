// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/common.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_failed) {
      setState(() => _failed = false);
    }
    final controller = AppScope.read(context);
    try {
      await Future.wait<void>([
        controller.init(),
        Future<void>.delayed(const Duration(milliseconds: 1400)),
      ]);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => controller.onboardingDone
              ? const MainShell()
              : const OnboardingScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HabitLogo(size: 150),
                const SizedBox(height: 20),
                Text('Habit Buddy',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Small steps, every day.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 32),
                if (_failed) ...[
                  Text(
                    'Something went wrong while opening your habits.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _start, child: const Text('Try again')),
                ] else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}