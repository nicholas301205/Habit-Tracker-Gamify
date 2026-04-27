import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/stats_service.dart';
import 'auth_provider.dart';

final statsServiceProvider = Provider((ref) => StatsService());

final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) {
    return WeeklyStats(
      completionRates: List.filled(7, 0.0),
      dayLabels: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
      totalCompleted: 0,
      longestStreak: 0,
      currentStreak: 0,
      avgPerDay: 0,
    );
  }
  return ref.watch(statsServiceProvider).getWeeklyStats(uid);
});