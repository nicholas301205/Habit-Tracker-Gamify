import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:habbit_tracker_gamify/core/utils/xp_utils.dart';
import '../models/habit_model.dart';
import '../services/firestore_services.dart';
import '../services/notification_service.dart';
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

class HabitCompleteResult {
  final int xpEarned;
  final int newStreak;
  final int newLevel;
  final bool didLevelUp;
  final List<String> newlyUnlockedBadges;

  HabitCompleteResult({
    required this.xpEarned,
    required this.newStreak,
    required this.newLevel,
    required this.didLevelUp,
    required this.newlyUnlockedBadges,
  });
}

// Notifier untuk aksi CRUD
class HabitNotifier extends StateNotifier<HabitState> {
  final FirestoreService _service;
  final String userId;

  HabitNotifier(this._service, this.userId)
    : super(HabitState.initial());

  Future<void> completeHabit(String habitId, int currentUserLevel) async {
  state = state.copyWith(isLoading: true, levelUpTo: null, newlyUnlockedBadges: []);
  try {
    // Panggil method lama yang sudah pasti ada
    final newlyUnlockedBadges = await _service.completeHabit(
      habitId: habitId,
      userId: userId,
    );

    // Cek level up langsung dari Firestore
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final newXp   = userSnap.data()?['xp'] as int? ?? 0;
    final newLevel = XpUtils.levelFromXp(newXp);

    if (newLevel > currentUserLevel) {
      state = state.copyWith(
        isLoading: false,
        levelUpTo: newLevel,
        newlyUnlockedBadges: newlyUnlockedBadges,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        newlyUnlockedBadges: newlyUnlockedBadges,
      );
    }
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}

  Future<void> addHabit({
    required String name,
    required String category,
    required String frequency,
    TimeOfDay? reminderTime,
  }) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    await _service.createHabit(
      userId: userId,
      name: name,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
    );

    state = state.copyWith(isLoading: false);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
  }

  Future<void> editHabit({
    required String habitId,
    required String name,
    required String category,
    required String frequency,
    TimeOfDay? reminderTime,
  }) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    await _service.updateHabit(
      habitId: habitId,
      name: name,
      category: category,
      frequency: frequency,
      reminderTime: reminderTime,
    );

    state = state.copyWith(isLoading: false);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
  }

  Future<void> deleteHabit(String habitId, String habitName) async {
    state = state.copyWith(isLoading: true, error: null);
     try {
    // Cancel any scheduled notifications for this habit
    await NotificationService.cancelReminder(habitName.hashCode);

    await _service.archiveHabit(habitId);

    state = state.copyWith(isLoading: false);
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
  }

  void clearLevelUp() {
    state = state.copyWith(levelUpTo: null);
  }
}

class HabitState {
  final bool isLoading;
  final int? levelUpTo;  // null = tidak ada level up
  final String? error;
  final List<String> newlyUnlockedBadges;

  const HabitState({
    required this.isLoading,
    this.levelUpTo,
    this.error,
    this.newlyUnlockedBadges = const [],
  });

  factory HabitState.initial() => const HabitState(isLoading: false);

  HabitState copyWith({
    bool? isLoading,
    int? levelUpTo,
    String? error,
    List<String>? newlyUnlockedBadges,
  }) {
    return HabitState(
      isLoading: isLoading ?? this.isLoading,
      levelUpTo: levelUpTo,
      error: error ?? this.error,
      newlyUnlockedBadges: newlyUnlockedBadges ?? this.newlyUnlockedBadges,
    );
  }
}

final habitNotifierProvider =
    StateNotifierProvider<HabitNotifier, HabitState>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  return HabitNotifier(ref.watch(firestoreServiceProvider), uid);
});

