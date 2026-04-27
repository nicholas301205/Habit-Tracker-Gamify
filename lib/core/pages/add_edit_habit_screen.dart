import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/services/notification_service.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';


class AddEditHabitScreen extends ConsumerStatefulWidget {
  final HabitModel? habit; // null = mode tambah, ada = mode edit
  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  TimeOfDay? _reminderTime;
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _category = 'Health';
  String _frequency = 'daily';

  bool get _isEdit => widget.habit != null;

  final _categories = ['Health', 'Study', 'Productivity', 'Other'];
  final _frequencies = ['daily', 'weekly'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.habit!.name;
      _category = widget.habit!.category;
      _frequency = widget.habit!.frequency;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(habitNotifierProvider.notifier);

    if (_reminderTime != null) {
  // Gunakan hashCode nama habit sebagai ID notifikasi
      await NotificationService.scheduleDailyReminder(
        id: _nameCtrl.text.hashCode,
        habitName: _nameCtrl.text.trim(),
        hour: _reminderTime!.hour,
        minute: _reminderTime!.minute,
      );
    }

    if (_isEdit) {
      await notifier.editHabit(
        habitId: widget.habit!.id,
        name: _nameCtrl.text.trim(),
        category: _category,
        frequency: _frequency,
      );
    } else {
      await notifier.addHabit(
        name: _nameCtrl.text.trim(),
        category: _category,
        frequency: _frequency,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(habitNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'Add Habit'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              

              // Nama habit
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g., Morning Exercise',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Habit name cannot be empty' : null,
              ),
              const SizedBox(height: 20),

              // Kategori
              const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Frekuensi
              const Text('Frequency',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: _frequencies.map((freq) {
                  final selected = _frequency == freq;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () => setState(() => _frequency = freq),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          foregroundColor: selected ? Colors.white : null,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(freq == 'daily' ? 'Harian' : 'Weekly'),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),

              // Pengingat
              ListTile(
              leading: const Icon(Icons.alarm),
              title: Text(_reminderTime == null
                  ? 'Set Reminder (Optional)'
                  : 'Reminder: ${_reminderTime!.format(context)}'),
              trailing: _reminderTime != null
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _reminderTime = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 7, minute: 0),
                );
                if (picked != null) setState(() => _reminderTime = picked);
              },
            ),

              // Tombol simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Save Changes' : 'Add Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}