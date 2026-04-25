import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String frequency;
  final int streakCurrent;
  final int streakLongest;
  final bool isActive;
  final DateTime createdAt;

  HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.frequency,
    required this.streakCurrent,
    required this.streakLongest,
    required this.isActive,
    required this.createdAt,
  });

  factory HabitModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HabitModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      name: d['name'] ?? '',
      category: d['category'] ?? 'Other',
      frequency: d['frequency'] ?? 'daily',
      streakCurrent: d['streakCurrent'] ?? 0,
      streakLongest: d['streakLongest'] ?? 0,
      isActive: d['isActive'] ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}