import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final int xp;
  final int level;
  final List<String> badges;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.xp,
    required this.level,
    required this.badges,
    required this.createdAt,
  });

  // XP per level = 100. Level naik tiap 100 XP
  int get xpToNextLevel => 100 - (xp % 100);
  double get xpProgress => (xp % 100) / 100;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: d['uid'] ?? '',
      username: d['username'] ?? '',
      email: d['email'] ?? '',
      xp: d['xp'] ?? 0,
      level: d['level'] ?? 1,
      badges: List<String>.from(d['badges'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'username': username,
    'email': email,
    'xp': xp,
    'level': level,
    'badges': badges,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}