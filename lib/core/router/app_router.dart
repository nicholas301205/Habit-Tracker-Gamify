import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// AUTH
import 'package:habbit_tracker_gamify/providers/auth_provider.dart';

// PAGES
import 'package:habbit_tracker_gamify/core/pages/splash_screen.dart';
import 'package:habbit_tracker_gamify/core/pages/login_screen.dart';
import 'package:habbit_tracker_gamify/core/pages/register_screen.dart';
import 'package:habbit_tracker_gamify/core/pages/home_screen.dart';
import 'package:habbit_tracker_gamify/core/pages/ai_chat_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',

    /// 🔁 REDIRECT LOGIC
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      // ✅ SUDAH LOGIN → jangan ke auth page
      if (isLoggedIn && isAuthRoute) return '/home';

      // ❌ BELUM LOGIN → jangan akses halaman utama
      if (!isLoggedIn && !isAuthRoute) return '/login';

      return null;
    },

    /// 📍 ROUTES
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),

      /// 🔥 TAMBAHAN AI CHAT
      GoRoute(
        path: '/ai',
        builder: (_, __) => const AIChatScreen(),
      ),
    ],
  );
});