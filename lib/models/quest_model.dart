import 'package:cloud_firestore/cloud_firestore.dart';

class QuestModel {
  final String dateString;
  final int target;
  final int completed;
  final bool isDone;
  final bool bonusXpClaimed;

  const QuestModel({
    required this.dateString,
    required this.target,
    required this.completed,
    required this.isDone,
    required this.bonusXpClaimed,
  });

  double get progress => completed / target;
  int get remaining => (target - completed).clamp(0, target);

  factory QuestModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return QuestModel(
      dateString: doc.id,
      target: d['target'] ?? 3,
      completed: d['completed'] ?? 0,
      isDone: d['isDone'] ?? false,
      bonusXpClaimed: d['bonusXpClaimed'] ?? false,
    );
  }
}