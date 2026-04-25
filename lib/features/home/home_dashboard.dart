import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../../providers/user_provider.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final completedAsync = ref.watch(completedTodayProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── HEADER ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: userAsync.when(
                  loading: () => const SizedBox(height: 80),
                  error: (_, __) => const SizedBox(),
                  data: (user) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${user?.username ?? ''}! 👋',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Text('Ayo selesaikan habit hari ini',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          // Level badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 14),
                                const SizedBox(width: 4),
                                Text('Lv. ${user?.level ?? 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // XP Progress bar
                      if (user != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${user.xp} XP',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Text('${user.xpToNextLevel} XP lagi ke Level ${user.level + 1}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.xpProgress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── PROGRESS SUMMARY ──────────────────────────────
            SliverToBoxAdapter(
              child: completedAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (completed) => habitsAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (habits) {
                    final total = habits.length;
                    final done = completed.length;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer
                              .withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Progress Hari Ini',
                                    style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$done / $total habit selesai',
                                    style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Circle progress
                            SizedBox(
                              width: 48, height: 48,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: total == 0 ? 0 : done / total,
                                    strokeWidth: 5,
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                  Text(
                                    total == 0 ? '-' : '${(done/total*100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── LIST HABIT HARI INI ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    const Text('Habit Hari Ini',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _todayLabel(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            habitsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
              data: (habits) => completedAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
                data: (completed) {
                  if (habits.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('Belum ada habit. Tambah dulu di tab Habit!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _HabitCheckCard(
                          habit: habits[i],
                          isDone: completed.contains(habits[i].id),
                        ),
                        childCount: habits.length,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun',
                    'Jul','Agu','Sep','Okt','Nov','Des'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// ── HABIT CHECK CARD ───────────────────────────────────────
class _HabitCheckCard extends ConsumerWidget {
  final HabitModel habit;
  final bool isDone;
  const _HabitCheckCard({required this.habit, required this.isDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDone
              ? Colors.green.withOpacity(0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone ? Colors.green : Colors.grey.shade200,
          ),
        ),
        child: ListTile(
          leading: GestureDetector(
            onTap: isDone
                ? null
                : () => ref
                    .read(habitNotifierProvider.notifier)
                    .completeHabit(habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? Colors.green
                    : Colors.transparent,
                border: Border.all(
                  color: isDone ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            habit.name,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Colors.grey : null,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.local_fire_department,
                size: 13, color: Colors.orange[700]),
              Text(' ${habit.streakCurrent} hari',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(habit.category,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          trailing: isDone
              ? const Chip(
                  label: Text('Selesai ✓',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              : Text('+10 XP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}