import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/habit_model.dart';
import '../services/firestore_services.dart';
import 'auth_provider.dart';

// Stream semua habit user yang aktif
final habitListProvider = StreamProvider<List<HabitModel>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchHabits(uid);
});

// Provider untuk cek habit mana yang sudah done hari ini
final completedTodayProvider = StreamProvider<List<String>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchCompletedToday(uid);
});

// Notifier untuk aksi CRUD
class HabitNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _service;
  final String userId;

  HabitNotifier(this._service, this.userId) : super(const AsyncData(null));

  Future<void> addHabit({
    required String name,
    required String category,
    required String frequency,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.createHabit(
      userId: userId,
      name: name,
      category: category,
      frequency: frequency,
    ));
  }

  Future<void> editHabit({
    required String habitId,
    required String name,
    required String category,
    required String frequency,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateHabit(
      habitId: habitId,
      name: name,
      category: category,
      frequency: frequency,
    ));
  }

  Future<void> deleteHabit(String habitId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _service.archiveHabit(habitId),
    );
  }

  Future<void> completeHabit(String habitId) async {
    state = await AsyncValue.guard(() => _service.completeHabit(
      habitId: habitId,
      userId: userId,
    ));
  }
}

final habitNotifierProvider =
    StateNotifierProvider<HabitNotifier, AsyncValue<void>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  return HabitNotifier(ref.watch(firestoreServiceProvider), uid);
});