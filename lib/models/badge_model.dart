import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final bool isUnlocked;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    this.isUnlocked = false,
  });

  BadgeModel copyWith({bool? isUnlocked}) {
    return BadgeModel(
      id: id,
      name: name,
      description: description,
      emoji: emoji,
      color: color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  // Semua badge yang ada di app — single source of truth
  static const List<BadgeModel> allBadges = [
    BadgeModel(
      id: 'first_step',
      name: 'First Step',
      description: 'Finish your first habit',
      emoji: '🌱',
      color: Color(0xFF4CAF50),
    ),
    BadgeModel(
      id: 'on_fire',
      name: 'On Fire',
      description: 'Complete a 3-day streak',
      emoji: '🔥',
      color: Color(0xFFFF9800),
    ),
    BadgeModel(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Complete a 7-day streak',
      emoji: '⚡',
      color: Color(0xFFF44336),
    ),
    BadgeModel(
      id: 'level_up',
      name: 'Level Up!',
      description: 'Reach Level 5',
      emoji: '⭐',
      color: Color(0xFF9C27B0),
    ),
    BadgeModel(
      id: 'quest_master',
      name: 'Quest Master',
      description: 'Complete your first daily quest',
      emoji: '🎯',
      color: Color(0xFF2196F3),
    ),
    BadgeModel(
      id: 'collector',
      name: 'Collector',
      description: 'Add 5 active habits',
      emoji: '🏆',
      color: Color(0xFF795548),
    ),
  ];
}