import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore_db = FirebaseFirestore.instance;

  // USERS
  Future<void> createUserDocument(User firebaseUser) async {
    final docRef = FirebaseFirestore.instance
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

  // LOGS
  Future<void> completeHabit({
    required String habitId,
    required String userId,
  }) async {
    final db = FirebaseFirestore.instance;
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2,'0')}'
                    '-${today.day.toString().padLeft(2,'0')}';

    // 1. Cek apakah sudah selesai hari ini
    final existing = await db.collection('habitLogs')
        .where('habitId', isEqualTo: habitId)
        .where('dateString', isEqualTo: dateStr)
        .get();

    if (existing.docs.isNotEmpty) return; // sudah centang hari ini

    const xpReward = 10;
    final batch = db.batch();

    // 2. Tambah log baru
    final logRef = db.collection('habitLogs').doc();
    batch.set(logRef, {
      'habitId': habitId,
      'userId': userId,
      'completedAt': FieldValue.serverTimestamp(),
      'xpEarned': xpReward,
      'dateString': dateStr,
    });

    // 3. Tambah XP ke user
    final userRef = db.collection('users').doc(userId);
    batch.update(userRef, {
      'xp': FieldValue.increment(xpReward),
    });

    await batch.commit(); // atomik — keduanya berhasil atau keduanya gagal
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