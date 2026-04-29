import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/core/utils/xp_utils.dart';
import 'package:habbit_tracker_gamify/core/components/level_up_dialog.dart';
import 'package:habbit_tracker_gamify/core/components/quest_card_widget.dart';
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
                padding: const EdgeInsets.all(20),
                child: userAsync.when(
                  loading: () => const SizedBox(height: 120),
                  error: (_, __) => const SizedBox(),
                  data: (user) {
                    if (user == null) return const SizedBox();

                    final color = Theme.of(context).colorScheme.primary;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.9),
                            color.withOpacity(0.6),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user.username}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Keep going. Level up your life 🚀',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),

                          // XP BAR
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: user.xpProgress,
                              minHeight: 10,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${user.xp} XP',
                                  style:
                                      const TextStyle(color: Colors.white)),
                              Text('Lv. ${user.level}',
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // PROGRESS SUMMARY
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Today's Progress",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      )),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$done / $total habits',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // 🔥 optional improvement
                                  Text(
                                    done == total
                                        ? "All habits completed 🎉"
                                        : "Keep going!",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // RIGHT SIDE (bigger & centered)
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: total == 0 ? 0 : done / total,
                                    strokeWidth: 6,
                                  ),
                                  Text(
                                    total == 0
                                        ? '-'
                                        : '${(done / total * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      )
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: QuestCardWidget(),
              ),
            ),

            // ── LIST HABIT HARI INI ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today’s Missions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _todayLabel(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                )
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// Tambahkan OverlayEntry saat habit di-centang

class _XpFloatWidget extends StatefulWidget {
  final String text;
  final Offset position;
  final VoidCallback onDone;
  const _XpFloatWidget({
    required this.text,
    required this.position,
    required this.onDone,
  });

  @override
  State<_XpFloatWidget> createState() => _XpFloatWidgetState();
}

class _XpFloatWidgetState extends State<_XpFloatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0)),
    );
    _slide = Tween(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.3),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx + 20,
      top: widget.position.dy,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HABIT CHECK CARD ───────────────────────────────────────
class _HabitCheckCard extends ConsumerWidget {
  final HabitModel habit;
  final bool isDone;
  const _HabitCheckCard({required this.habit, required this.isDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<HabitState>(habitNotifierProvider, (prev, next) {
      if (next.levelUpTo != null && next.levelUpTo != prev?.levelUpTo) {
        LevelUpDialog.show(
          context,
          newLevel: next.levelUpTo!,
          levelTitle: XpUtils.levelTitle(next.levelUpTo!),
        ).then((_) {
          ref.read(habitNotifierProvider.notifier).clearLevelUp();
        });
      }
    });

    final categoryColors = {
      'Health': Colors.green,
      'Study': Colors.blue,
      'Productivity': Colors.orange,
      'Other': Colors.purple,
    };
    final color = categoryColors[habit.category] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDone
          ? null
          : () async {
              // Haptic feedback saat centang
              HapticFeedback.mediumImpact();

              final user = ref.read(currentUserProvider).asData?.value;
              ref.read(habitNotifierProvider.notifier)
                  .completeHabit(habit.id, user?.currentLevel ?? 1);
            },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDone
                  ? Colors.green.withOpacity(0.1)
                  : Theme.of(context).cardColor,
              boxShadow: [
                if (!isDone)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Row(
              children: [
                // ── Circle checkbox ──────────────────────────
                TweenAnimationBuilder(
                  tween: Tween(begin: 1.0, end: isDone ? 0.98 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),

                // ── Nama & info habit ────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 13, color: Colors.orange[700]),
                          Text(' ${habit.streakCurrent} days streak',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              habit.category,
                              style: TextStyle(fontSize: 10, color: color),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Trailing ─────────────────────────────────
                isDone
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 24)
                    : Text(
                      '+10 XP',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                      ),
                    )
              ],
            ),
          ),
        ),
      ),
    );
  }
}