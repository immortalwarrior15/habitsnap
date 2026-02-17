import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';

class MeditationApp extends ConsumerWidget {
  const MeditationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(meditationControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meditation & Relax',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
