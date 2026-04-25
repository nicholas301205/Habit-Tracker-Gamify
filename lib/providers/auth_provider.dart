import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:habbit_tracker_gamify/services/auth_services.dart';

// Provider untuk AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider stream status login — dipakai go_router untuk redirect
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provider untuk state login form (loading, error)
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.login(email: email, password: password),
    );
  }

  Future<void> register(String email, String password, String username) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.register(
        email: email,
        password: password,
        username: username,
      ),
    );
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AsyncData(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});