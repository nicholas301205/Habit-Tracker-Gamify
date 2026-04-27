import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart';
import '../core/utils/xp_utils.dart';

class BadgeService {
  final _db = FirebaseFirestore.instance;

  // Cek & unlock badge yang relevan setelah habit selesai
  Future<List<String>> checkAndUnlockBadges({
    required String userId,
    required int newStreak,
    required int totalXp,
    required int habitCount,
    required bool questCompleted,
    required bool isFirstHabit, // apakah ini habit pertama yang diselesaikan
  }) async {
    print('=== BADGE CHECK START ===');
    // Ambil badges yang sudah dimiliki user
    final userDoc = await _db.collection('users').doc(userId).get();
    final ownedBadges = List<String>.from(
      userDoc.data()?['badges'] ?? [],
    );

    final newlyUnlocked = <String>[];
    final toAdd = <String>[];

    // ─ Cek tiap kondisi badge ────────────────────────────
    void tryUnlock(String badgeId, bool condition) {
    print('CHECK BADGE: $badgeId | condition: $condition');

    if (condition && !ownedBadges.contains(badgeId)) {
      print('>>> UNLOCKING BADGE: $badgeId');
      toAdd.add(badgeId);
      newlyUnlocked.add(badgeId);
    }
  }

    tryUnlock('first_step', isFirstHabit);
    tryUnlock('on_fire', newStreak >= 3);
    tryUnlock('week_warrior', newStreak >= 7);
    tryUnlock('level_up', XpUtils.levelFromXp(totalXp) >= 5);
    tryUnlock('quest_master', questCompleted);
    tryUnlock('collector', habitCount >= 5);

    // Update Firestore jika ada badge baru
    if (toAdd.isNotEmpty) {
    print('UPDATING BADGES: $toAdd');

    await _db.collection('users').doc(userId).update({
      'badges': FieldValue.arrayUnion(toAdd),
    });
  } else {
    print('NO BADGE UNLOCKED');
  }

    print('RETURN BADGES: $newlyUnlocked');
    return newlyUnlocked; // list badge ID yang baru di-unlock
  }

  // Ambil list badge dengan status unlocked dari user
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    final owned = List<String>.from(doc.data()?['badges'] ?? []);

    return BadgeModel.allBadges.map((b) {
      return b.copyWith(isUnlocked: owned.contains(b.id));
    }).toList();
  }

  // Stream realtime badges user
  Stream<List<BadgeModel>> watchUserBadges(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      final owned = List<String>.from(doc.data()?['badges'] ?? []);
      return BadgeModel.allBadges.map((b) {
        return b.copyWith(isUnlocked: owned.contains(b.id));
      }).toList();
    });
  }
}