import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/core/utils/xp_utils.dart';
import 'package:habbit_tracker_gamify/models/habit_model.dart';
import 'package:habbit_tracker_gamify/models/user_model.dart';
import 'package:habbit_tracker_gamify/services/badge_services.dart';

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

  // WATCH HABITS (realtime stream)
  Stream<List<HabitModel>> watchHabits(String userId) {
    return _db
        .collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .handleError((e) => print('=== watchHabits ERROR: $e ==='))
        .map((snap) => snap.docs.map(HabitModel.fromFirestore).toList());
  }

  // UPDATE HABIT
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

  Future<void> archiveHabit(String habitId) async {
    await _db.collection('habits').doc(habitId).update({
      'isActive': false,
    });
  }

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
        .handleError((e) => print('=== watchCompletedToday ERROR: $e ==='))
        .map((snap) => snap.docs
            .map((d) => d.data()['habitId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }

  // LOGS
  Future<void> completeHabit({
    required String habitId,
    required String userId,
  }) async {
    final today = DateTime.now();
    final todayStr = _dateStr(today);
    final yesterdayStr = _dateStr(today.subtract(const Duration(days: 1)));

    print(' FUNCTION CALL TRACE: completeHabit  ${DateTime.now().millisecondsSinceEpoch}');
    print(' completeHabit START ');
    print('Today: $todayStr | Yesterday: $yesterdayStr');
    print('HabitId: $habitId | UserId: $userId');

  // 1. Cek sudah selesai hari ini?
  await _db.runTransaction((transaction) async {
  final existing = await _db.collection('habitLogs')
  
      .where('userId', isEqualTo: userId)
      .where('habitId', isEqualTo: habitId)
      .where('dateString', isEqualTo: todayStr)
      .get();

  print('STEP 1 - Existing logs today: ${existing.docs.length}');

  if (existing.docs.isNotEmpty) {
    print(' STOPPED: already completed today ');
    return;
  }});

  // 2. Cek kalau ada log kemarin (untuk streak)
  final yesterdayLog = await _db.collection('habitLogs')
      .where('userId', isEqualTo: userId)
      .where('habitId', isEqualTo: habitId)
      .where('dateString', isEqualTo: yesterdayStr)
      .get();

    print('STEP 2 - Yesterday logs: ${yesterdayLog.docs.length}');

  // 3. Ambil data habit sekarang (streak saat ini)
  final habitSnap = await _db.collection('habits').doc(habitId).get();

  if (!habitSnap.exists) {
    print(' ERROR: habit document not found for habitId: $habitId ===');
    return;
  }

  final habitData = habitSnap.data() as Map<String, dynamic>;
  final currentStreak = habitData['streakCurrent'] as int? ?? 0;
  final longestStreak = habitData['streakLongest'] as int? ?? 0;

  print('STEP 3 - Current streak: $currentStreak | Longest: $longestStreak');

  // 4. Hitung streak baru
  final newStreak = yesterdayLog.docs.isNotEmpty
      ? currentStreak + 1   // lanjut streak
      : 1;                  // reset ke 1
  final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

  print('STEP 4 - New streak: $newStreak | New longest: $newLongest');
  print('Streak continued: ${yesterdayLog.docs.isNotEmpty}');

  final xpReward = XpUtils.calculateXpReward(newStreak);
  
  print('STEP 4 - XP reward: $xpReward');


  try {
    final batch = _db.batch();

  // 5. Simpan log baru
  final logId = '${userId}_${habitId}_$todayStr';
  final logRef = _db.collection('habitLogs').doc(logId);
  print('DEBUG - EXPECTED LOG ID: $logId');

  // Penting iskal! Cek ulang kalau log sudah ada sebelum buat, untuk mencegah duplikat
  await logRef.get();
  if ((await logRef.get()).exists) return;

  batch.set(logRef, {
    'habitId': habitId,
    'userId': userId,
    'completedAt': FieldValue.serverTimestamp(),
    'xpEarned': xpReward,
    'dateString': todayStr,
  });
  print('STEP 5 - Log doc prepared: ${logRef.id}');

  // 6. Update streak di habit
  final habitRef = _db.collection('habits').doc(habitId);
  batch.update(habitRef, {
    'streakCurrent': newStreak,
    'streakLongest': newLongest,
  });
  print('STEP 5 - Habit update prepared');

  // 7. Tambah XP ke user
  final userRef = _db.collection('users').doc(userId);
  batch.update(userRef, {
    'xp': FieldValue.increment(xpReward),
  });
  print('STEP 5 - User XP update prepared');

  await batch.commit();
  print(' STEP 5 - batch.commit() SUCCESS ');

  } catch (e) {
    print(' STEP 5 - batch.commit() FAILED: $e ');
    return;
  }

  await _db.collection('habitLogs')
    .where('userId', isEqualTo: userId)
    .where('dateString', isEqualTo: todayStr)
    .get();

  final logs = await _db.collection('habitLogs')
    .where('userId', isEqualTo: userId)
    .get();

  print('DEBUG - TOTAL LOGS: ${logs.docs.length}');

    

    // 3. HABIT COUNT (unik)
    final habitIds = logs.docs
        .map((d) => d.data()['habitId'] as String)
        .toSet();

    print('DEBUG - habitIds: $habitIds');

    final habitCount = habitIds.length;
    print('DEBUG - habitCount: $habitCount');

    print('STEP BADGE - habitCount: $habitCount');

    final isFirstHabit = logs.docs.length == 1;
    print('DEBUG - isFirstHabit: $isFirstHabit');

    print('STEP BADGE - isFirstHabit: $isFirstHabit');

  // 8. Update quest progress
  await updateQuestProgress(userId);

  final dateStr = _dateStr(DateTime.now());

  final questDoc = await _db
    .collection('users')
    .doc(userId)
    .collection('dailyQuests')
    .doc(dateStr)
    .get();

final questCompleted = questDoc.data()?['isDone'] == true;

print('STEP BADGE - questCompleted: $questCompleted');

  await _db
      .collection('users')
      .doc(userId)
      .collection('dailyQuests')
      .doc(todayStr)
      .get();


  print('STEP BADGE - questCompleted: $questCompleted');

  // 9. Cek level up
  try {
  final userSnap = await _db.collection('users').doc(userId).get();
  final totalXp = userSnap.data()?['xp'] ?? 0;
  final badgeService = BadgeService();

  print('=== BADGE INPUT DEBUG ===');
  print('userId: $userId');
  print('newStreak: $newStreak');
  print('totalXp: $totalXp');
  print('habitCount: $habitCount');
  print('questCompleted: $questCompleted');
  print('isFirstHabit: $isFirstHabit');

  await badgeService.checkAndUnlockBadges(
    userId: userId,
    newStreak: newStreak,
    totalXp: totalXp,
    habitCount: habitCount,
    questCompleted: questCompleted,
    isFirstHabit: isFirstHabit,
  );
  final newXp = userSnap.data()!['xp'] as int? ?? 0;
  final newLevel = XpUtils.levelFromXp(newXp);
  final currentLevel = userSnap.data()!['level'] as int? ?? 1;

  print('STEP 6 - New XP: $newXp | New level: $newLevel | Current level: $currentLevel');


  if (newLevel > currentLevel) {
    await _db.collection('users').doc(userId).update({'level': newLevel});
    print('STEP 6 - LEVEL UP to $newLevel!');
    // Return info level up ke caller (pakai state di provider)
  }
} catch (e) {
    print(' STEP 6 ERROR: $e ');
  }}

// Format date ke string "yyyy-MM-dd"
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
  
  Future<void> updateQuestProgress(String userId) async {

    final dateStr = _dateStr(DateTime.now());
    final questRef = FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('dailyQuests').doc(dateStr);

    final snap = await questRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;

    if (data['isDone'] == true) {
    print('=== QUEST ALREADY DONE, SKIP UPDATE ===');
    return;
    }

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