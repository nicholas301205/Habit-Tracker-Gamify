import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';
import 'add_edit_habit_screen.dart';

class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Habit'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_task, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada habit',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 6),
                  Text('Tap + untuk tambah habit pertama',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _HabitCard(habit: habits[i]),
          );
        },
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitModel habit;
  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColors = {
      'Health': Colors.green,
      'Study': Colors.blue,
      'Productivity': Colors.orange,
      'Other': Colors.purple,
    };
    final color = categoryColors[habit.category] ?? Colors.grey;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.repeat, color: color),
        ),
        title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(habit.category,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.local_fire_department, size: 14, color: Colors.orange[700]),
            Text(' ${habit.streakCurrent} hari',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (val) {
            if (val == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditHabitScreen(habit: habit),
                ),
              );
            } else if (val == 'delete') {
              _showDeleteDialog(context, ref);
            }
          },
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Habit?'),
        content: Text('Habit "${habit.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitNotifierProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}