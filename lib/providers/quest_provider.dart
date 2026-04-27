import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quest_model.dart';
import '../core/utils/xp_utils.dart';
import 'auth_provider.dart';

final todayQuestProvider = StreamProvider<QuestModel?>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(null);

  final db = FirebaseFirestore.instance;

  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}'
      '-${today.day.toString().padLeft(2, '0')}';

  print('=== QUEST PROVIDER RUNNING ===');
  print('UID: $uid');
  print('DATE: $dateStr');

  final docRef = db
      .collection('users')
      .doc(uid)
      .collection('dailyQuests')
      .doc(dateStr);

  // 🔥 AUTO INIT
  docRef.get().then((snap) {
    if (!snap.exists) {
      print('=== INIT DAILY QUEST ===');
      docRef.set({
        'target': 3,
        'completed': 0,
        'isDone': false,
        'bonusXpClaimed': false,
      });
    }
  });

  return docRef.snapshots().map((snap) {
    print('QUEST EXISTS: ${snap.exists}');
    print('QUEST DATA: ${snap.data()}');

    return snap.exists ? QuestModel.fromFirestore(snap) : null;
  });
});

// Claim bonus XP quest
Future<void> claimQuestBonus(String userId) async {
  final db = FirebaseFirestore.instance;
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}'
      '-${today.day.toString().padLeft(2, '0')}';

  final questRef = db
      .collection('users')
      .doc(userId)
      .collection('dailyQuests')
      .doc(dateStr);

  final snap = await questRef.get();
  if (!snap.exists) return;

  final data = snap.data()!;
  if (data['bonusXpClaimed'] == true) return; // sudah diklaim

  final batch = db.batch();
  batch.update(questRef, {'bonusXpClaimed': true});
  batch.update(db.collection('users').doc(userId), {
    'xp': FieldValue.increment(XpUtils.xpQuestComplete),
  });
  await batch.commit();
}