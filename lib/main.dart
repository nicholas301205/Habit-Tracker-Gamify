import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:habbit_tracker_gamify/providers/theme_provider.dart';
import 'package:habbit_tracker_gamify/services/notification_service.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 LOAD ENV (WAJIB untuk AI)
  await dotenv.load(fileName: ".env");

  /// 🔥 FIREBASE INIT
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔔 NOTIFICATION INIT
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: HabitQuestApp(),
    ),
  );
}

class HabitQuestApp extends ConsumerWidget {
  const HabitQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'HabitQuest',

      /// 🎨 THEME
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      /// 🔀 ROUTER
      routerConfig: router,

      debugShowCheckedModeBanner: false,
    );
  }
}