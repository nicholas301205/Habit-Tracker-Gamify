import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyStats {
  final List<double> completionRates; // 7 nilai 0.0–1.0 (Sen–Min)
  final List<String> dayLabels;       // ['Sen','Sel',...]
  final int totalCompleted;
  final int longestStreak;
  final int currentStreak;
  final double avgPerDay;

  const WeeklyStats({
    required this.completionRates,
    required this.dayLabels,
    required this.totalCompleted,
    required this.longestStreak,
    required this.currentStreak,
    required this.avgPerDay,
  });
}

class StatsService {
  final _db = FirebaseFirestore.instance;

  Future<WeeklyStats> getWeeklyStats(String userId) async {
    final now = DateTime.now();

    // Ambil 7 hari terakhir
    final days = List.generate(7, (i) {
      return now.subtract(Duration(days: 6 - i));
    });

    final dayLabels = days.map((d) {
      const labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return labels[d.weekday - 1];
    }).toList();

    // Format semua tanggal jadi string
    final dateStrings = days.map((d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}'
      '-${d.day.toString().padLeft(2,'0')}'
    ).toList();

    // Ambil semua log dalam 7 hari
    final logsSnap = await _db.collection('habitLogs')
        .where('userId', isEqualTo: userId)
        .where('dateString', whereIn: dateStrings)
        .get();

    // Hitung total habit aktif
    final habitsSnap = await _db.collection('habits')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    final totalHabits = habitsSnap.docs.length;

    // Group logs per tanggal
    final logsByDate = <String, int>{};
    for (final doc in logsSnap.docs) {
      final date = doc.data()['dateString'] as String;
      logsByDate[date] = (logsByDate[date] ?? 0) + 1;
    }

    // Hitung completion rate tiap hari
    final completionRates = dateStrings.map((dateStr) {
      if (totalHabits == 0) return 0.0;
      final completed = logsByDate[dateStr] ?? 0;
      return (completed / totalHabits).clamp(0.0, 1.0);
    }).toList();

    // Hitung streak terpanjang dari semua habit
    int longestStreak = 0;
    int currentStreak = 0;
    for (final habit in habitsSnap.docs) {
      final d = habit.data();
      final ls = d['streakLongest'] as int? ?? 0;
      final cs = d['streakCurrent'] as int? ?? 0;
      if (ls > longestStreak) longestStreak = ls;
      if (cs > currentStreak) currentStreak = cs;
    }

    final totalCompleted = logsSnap.docs.length;
    final avgPerDay = totalCompleted / 7;

    return WeeklyStats(
      completionRates: completionRates,
      dayLabels: dayLabels,
      totalCompleted: totalCompleted,
      longestStreak: longestStreak,
      currentStreak: currentStreak,
      avgPerDay: double.parse(avgPerDay.toStringAsFixed(1)),
    );
  }
}