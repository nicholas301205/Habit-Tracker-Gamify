import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/models/habit_model.dart';
import 'package:habbit_tracker_gamify/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USERS
  Future<void> createUserDocument(User firebaseUser) async {
    final docRef = _db
        .collection('users')
        .doc(firebaseUser.uid);  // ← document ID = UID

    await docRef.set({
      'uid': firebaseUser.uid,
      'username': firebaseUser.displayName ?? 'Pengguna Baru',
      'email': firebaseUser.email ?? '',
      'xp': 0,
      'level': 1,
      'badges': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserModel?> watchUser(String uid) {
  return _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
}

  // HABITS
  Future<void> createHabit({
    required String userId,
    required String name,
    required String category,
    required String frequency,
  }) async {
    await FirebaseFirestore.instance.collection('habits').add({
      'userId': userId,
      'name': name,
      'category': category,
      'frequency': frequency,
      'streakCurrent': 0,
      'streakLongest': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Query: ambil semua habit milik user
  Stream<QuerySnapshot> getUserHabits(String userId) {
    return FirebaseFirestore.instance
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // ── WATCH HABITS (realtime stream) ──────────────────────
  Stream<List<HabitModel>> watchHabits(String userId) {
    return _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(HabitModel.fromFirestore).toList());
  }

  // ── UPDATE HABIT ──────────────────────────────────────
  Future<void> updateHabit({
    required String habitId,
    required String name,
    required String category,
    required String frequency,
  }) async {
    await _db.collection('habits').doc(habitId).update({
      'name': name,
      'category': category,
      'frequency': frequency,
    });
  }

  // ── ARCHIVE HABIT (soft delete) ───────────────────────
  Future<void> archiveHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).update({
      'isActive': false,
    });
  }

  // ── CEK HABIT DONE HARI INI ───────────────────────────
  Stream<List<String>> watchCompletedToday(String userId) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2,'0')}'
        '-${today.day.toString().padLeft(2,'0')}';

    return _db
        .collection('habitLogs')
        .where('userId', isEqualTo: userId)
        .where('dateString', isEqualTo: dateStr)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['habitId'] as String)
            .toList());
  }

  // LOGS
  // GANTI method completeHabit yang lama dengan ini:
Future<void> completeHabit({
  required String habitId,
  required String userId,
}) async {
  final today = DateTime.now();
  final todayStr = _dateStr(today);
  final yesterdayStr = _dateStr(today.subtract(const Duration(days: 1)));

  // 1. Cek sudah selesai hari ini?
  final existing = await _db.collection('habitLogs')
      .where('habitId', isEqualTo: habitId)
      .where('dateString', isEqualTo: todayStr)
      .get();

  if (existing.docs.isNotEmpty) return; // sudah centang, stop

  // 2. Cek apakah ada log kemarin (untuk streak)
  final yesterdayLog = await _db.collection('habitLogs')
      .where('habitId', isEqualTo: habitId)
      .where('dateString', isEqualTo: yesterdayStr)
      .get();

  // 3. Ambil data habit sekarang (streak saat ini)
  final habitSnap = await _db.collection('habits').doc(habitId).get();
  final habitData = habitSnap.data() as Map<String, dynamic>;
  final currentStreak = habitData['streakCurrent'] as int? ?? 0;
  final longestStreak = habitData['streakLongest'] as int? ?? 0;

  // 4. Hitung streak baru
  final newStreak = yesterdayLog.docs.isNotEmpty
      ? currentStreak + 1   // lanjut streak
      : 1;                  // reset ke 1

  final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

  const xpReward = 10;
  final batch = _db.batch();

  // 5. Simpan log baru
  final logRef = _db.collection('habitLogs').doc();
  batch.set(logRef, {
    'habitId': habitId,
    'userId': userId,
    'completedAt': FieldValue.serverTimestamp(),
    'xpEarned': xpReward,
    'dateString': todayStr,
  });

  // 6. Update streak di habit
  final habitRef = _db.collection('habits').doc(habitId);
  batch.update(habitRef, {
    'streakCurrent': newStreak,
    'streakLongest': newLongest,
  });

  // 7. Tambah XP ke user
  final userRef = _db.collection('users').doc(userId);
  batch.update(userRef, {
    'xp': FieldValue.increment(xpReward),
  });

  await batch.commit();

  // 8. Update quest progress
  await updateQuestProgress(userId);

  // 9. Cek level up
  final userSnap = await _db.collection('users').doc(userId).get();
  final newXp = (userSnap.data()!['xp'] as int? ?? 0);
  final newLevel = (newXp ~/ 100) + 1;
  final currentLevel = habitData['level'] as int? ?? 1;
  if (newLevel > currentLevel) {
    await _db.collection('users').doc(userId).update({'level': newLevel});
  }
}

// Helper: format date ke string "yyyy-MM-dd"
String _dateStr(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2,'0')}'
      '-${date.day.toString().padLeft(2,'0')}';
}

  // DAILY QUEST
  Future<void> initDailyQuest(String userId) async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}'
                    '-${today.day.toString().padLeft(2,'0')}';

    final questRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('dailyQuests')
        .doc(dateStr);

    final snap = await questRef.get();
    if (!snap.exists) {
      await questRef.set({
        'target': 3,
        'completed': 0,
        'isDone': false,
        'bonusXpClaimed': false,
      });
    }
  }

  // Update saat habit diselesaikan
  Future<void> updateQuestProgress(String userId) async {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final questRef = FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('dailyQuests').doc(dateStr);

    final snap = await questRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final newCompleted = (data['completed'] as int) + 1;
    final target = data['target'] as int;

    await questRef.update({
      'completed': newCompleted,
      'isDone': newCompleted >= target,
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});