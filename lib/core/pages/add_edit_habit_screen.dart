import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/services/notification_service.dart';
import '../../models/habit_model.dart';
import '../../providers/habit_provider.dart';

class AddEditHabitScreen extends ConsumerStatefulWidget {
  final HabitModel? habit;
  const AddEditHabitScreen({super.key, this.habit});

  @override
  ConsumerState<AddEditHabitScreen> createState() =>
      _AddEditHabitScreenState();
}

class _AddEditHabitScreenState
    extends ConsumerState<AddEditHabitScreen> {
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
      _reminderTime = widget.habit!.reminderTime;
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

    // Handle notifications
    final notificationId = _isEdit ? widget.habit!.id.hashCode : _nameCtrl.text.trim().hashCode;
    if (_isEdit && widget.habit!.reminderTime != null) {
      // Cancel old notification
      await NotificationService.cancelReminder(widget.habit!.id.hashCode);
    }

    if (_reminderTime != null) {
      await NotificationService.scheduleDailyReminder(
        id: notificationId,
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
        reminderTime: _reminderTime,
      );
    } else {
      await notifier.addHabit(
        name: _nameCtrl.text.trim(),
        category: _category,
        frequency: _frequency,
        reminderTime: _reminderTime,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(habitNotifierProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'New Habit'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHabitInfoSection(context),
                const SizedBox(height: 20),
                _buildScheduleSection(context),
                const SizedBox(height: 30),
                _buildSaveButton(isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //
  // 🔹 SECTION 1: HABIT INFO
  //
  Widget _buildHabitInfoSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Habit Info',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                hintText: 'e.g., Morning Exercise',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Required' : null,
            ),

            const SizedBox(height: 16),

            // Category
            const Text('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final selected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _category = cat),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  //
  // 🔹 SECTION 2: SCHEDULE
  //
  Widget _buildScheduleSection(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Frequency
            Row(
              children: _frequencies.map((freq) {
                final selected = _frequency == freq;
                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _frequency = freq),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                            : null,
                        foregroundColor:
                            selected ? Colors.white : null,
                      ),
                      child: Text(freq == 'daily'
                          ? 'Daily'
                          : 'Weekly'),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Reminder Card
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      const TimeOfDay(hour: 7, minute: 0),
                );
                if (picked != null) {
                  setState(() => _reminderTime = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _reminderTime == null
                            ? 'Set Reminder'
                            : _reminderTime!
                                .format(context),
                      ),
                    ),
                    if (_reminderTime != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(
                            () => _reminderTime = null),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
  // 🔹 CTA BUTTON
  //
  Widget _buildSaveButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2),
              )
            : Text(_isEdit
                ? 'Save Changes'
                : 'Create Habit'),
      ),
    );
  }
}