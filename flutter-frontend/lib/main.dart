import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SikanuaApp(),
    ),
  );
}

class SikanuaApp extends StatelessWidget {
  const SikanuaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIKANUA',
      debugShowCheckedModeBanner: false,
      theme: SikanuaTheme.theme,
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final step = context.watch<AppProvider>().step;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: switch (step) {
        AppStep.welcome => const WelcomeScreen(key: ValueKey('welcome')),
        AppStep.profile => const ProfileScreen(key: ValueKey('profile')),
        AppStep.chat    => const ChatScreen(key: ValueKey('chat')),
      },
    );
  }
}
