import 'package:cloud_firestore/cloud_firestore.dart';

class HabitLogModel {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final int xpEarned;
  final String dateString; // format: "2025-01-24"

  HabitLogModel({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    required this.xpEarned,
    required this.dateString,
  });

  factory HabitLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HabitLogModel(
      id: doc.id,
      habitId: d['habitId'] ?? '',
      userId: d['userId'] ?? '',
      completedAt: (d['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      xpEarned: d['xpEarned'] ?? 0,
      dateString: d['dateString'] ?? '',
    );
  }
}