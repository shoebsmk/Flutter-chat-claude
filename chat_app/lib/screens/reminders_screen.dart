import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

/// Screen displaying all reminders with add and complete functionality.
class RemindersScreen extends StatefulWidget {
  final bool autoAdd;

  const RemindersScreen({super.key, this.autoAdd = false});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _reminderService = ReminderService();

  List<Reminder> _reminders = [];
  bool _isLoading = true;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    if (widget.autoAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAddDialog());
    }
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminders = await _reminderService.getAll();
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    }
  }

  List<Reminder> get _displayedReminders {
    if (_showCompleted) return _reminders;
    return _reminders.where((r) => !r.isCompleted).toList();
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    bool isRecurring = false;
    RecurrenceType recurrenceType = RecurrenceType.daily;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXL),
                  ),
                ),
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'New Reminder',
                        style: AppTheme.headingSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'What to remember?',
                        ),
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'Add details...',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 365 * 5)),
                                );
                                if (date != null) {
                                  setSheetState(() {
                                    selectedDate = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      selectedTime.hour,
                                      selectedTime.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: Text(
                                DateFormat('MMM d, yyyy').format(selectedDate),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (time != null) {
                                  setSheetState(() {
                                    selectedTime = time;
                                    selectedDate = DateTime(
                                      selectedDate.year,
                                      selectedDate.month,
                                      selectedDate.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(selectedTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Recurring',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: isRecurring,
                        onChanged: (v) => setSheetState(() => isRecurring = v),
                      ),
                      if (isRecurring) ...[
                        SegmentedButton<RecurrenceType>(
                          segments: RecurrenceType.values.map((type) {
                            return ButtonSegment(
                              value: type,
                              label: Text(type.displayName),
                            );
                          }).toList(),
                          selected: {recurrenceType},
                          onSelectionChanged: (v) {
                            setSheetState(() => recurrenceType = v.first);
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Set Reminder'),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await _reminderService.add(
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        dueDate: selectedDate,
        isRecurring: isRecurring,
        recurrenceType: isRecurring ? recurrenceType : null,
      );
      _loadReminders();
    }

    titleController.dispose();
    descController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayed = _displayedReminders;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: AppTheme.headingSmall
              .copyWith(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() => _showCompleted = !_showCompleted);
            },
            icon: Icon(
              _showCompleted ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
            label: Text(_showCompleted ? 'Hide done' : 'Show done'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : displayed.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    itemCount: displayed.length,
                    itemBuilder: (context, index) {
                      final reminder = displayed[index];
                      return _ReminderCard(
                        reminder: reminder,
                        onToggle: () async {
                          HapticService.instance.lightImpact();
                          await _reminderService.toggleComplete(reminder.id);
                          _loadReminders();
                        },
                        onDelete: () async {
                          await _reminderService.delete(reminder.id);
                          _loadReminders();
                        },
                      )
                          .animate()
                          .fadeIn(
                            duration: AppConstants.animationNormal,
                            delay: Duration(milliseconds: index * 40),
                          )
                          .slideY(begin: 0.05, end: 0);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: AppTheme.successLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm,
                size: 64,
                color: AppTheme.successLight.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'No reminders',
              style: AppTheme.headingMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Never forget important things.\nTap + to set your first reminder.',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingL),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          side: reminder.isOverdue
              ? BorderSide(color: theme.colorScheme.error.withOpacity(0.5))
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: reminder.isCompleted
                          ? AppTheme.successLight
                          : reminder.isOverdue
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                      width: 2,
                    ),
                    color: reminder.isCompleted
                        ? AppTheme.successLight
                        : Colors.transparent,
                  ),
                  child: reminder.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingM),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (reminder.description != null &&
                          reminder.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reminder.description!,
                          style: AppTheme.caption.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingXS),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: reminder.isOverdue
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(reminder.dueDate),
                            style: AppTheme.caption.copyWith(
                              color: reminder.isOverdue
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                          if (reminder.isRecurring) ...[
                            const SizedBox(width: AppTheme.spacingS),
                            Icon(
                              Icons.repeat,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              reminder.recurrenceType?.displayName ?? '',
                              style: AppTheme.caption.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
