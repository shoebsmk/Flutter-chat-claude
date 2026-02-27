import '../models/reminder.dart';
import 'local_storage_service.dart';

/// Service for CRUD operations on reminders.
class ReminderService {
  static const String _storageKey = 'reminders';

  Future<List<Reminder>> getAll() async {
    final data = await LocalStorageService.loadList(_storageKey);
    final reminders = data.map((json) => Reminder.fromJson(json)).toList();
    // Sort: incomplete first (by due date), then completed
    reminders.sort((a, b) {
      if (!a.isCompleted && b.isCompleted) return -1;
      if (a.isCompleted && !b.isCompleted) return 1;
      return a.dueDate.compareTo(b.dueDate);
    });
    return reminders;
  }

  Future<Reminder> add({
    required String title,
    String? description,
    required DateTime dueDate,
    bool isRecurring = false,
    RecurrenceType? recurrenceType,
  }) async {
    final reminders = await getAll();
    final reminder = Reminder.create(
      title: title,
      description: description,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurrenceType: recurrenceType,
    );
    reminders.add(reminder);
    await _save(reminders);
    return reminder;
  }

  Future<void> toggleComplete(String id) async {
    final reminders = await getAll();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final reminder = reminders[index];
      if (!reminder.isCompleted && reminder.isRecurring) {
        // For recurring reminders, create next occurrence and mark current as done
        reminders[index] = reminder.copyWith(isCompleted: true);
        final nextDue = _getNextRecurrence(
          reminder.dueDate,
          reminder.recurrenceType!,
        );
        final nextReminder = Reminder.create(
          title: reminder.title,
          description: reminder.description,
          dueDate: nextDue,
          isRecurring: true,
          recurrenceType: reminder.recurrenceType,
        );
        reminders.add(nextReminder);
      } else {
        reminders[index] = reminder.copyWith(
          isCompleted: !reminder.isCompleted,
        );
      }
      await _save(reminders);
    }
  }

  Future<void> delete(String id) async {
    final reminders = await getAll();
    reminders.removeWhere((r) => r.id == id);
    await _save(reminders);
  }

  Future<void> update(Reminder reminder) async {
    final reminders = await getAll();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await _save(reminders);
    }
  }

  Future<List<Reminder>> getUpcoming() async {
    final reminders = await getAll();
    return reminders.where((r) => !r.isCompleted).toList();
  }

  Future<List<Reminder>> getDueToday() async {
    final reminders = await getAll();
    return reminders.where((r) => !r.isCompleted && r.isDueToday).toList();
  }

  Future<int> getOverdueCount() async {
    final reminders = await getAll();
    return reminders.where((r) => r.isOverdue).length;
  }

  DateTime _getNextRecurrence(DateTime current, RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return current.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return current.add(const Duration(days: 7));
      case RecurrenceType.monthly:
        return DateTime(current.year, current.month + 1, current.day,
            current.hour, current.minute);
    }
  }

  Future<void> _save(List<Reminder> reminders) async {
    final data = reminders.map((r) => r.toJson()).toList();
    await LocalStorageService.saveList(_storageKey, data);
  }
}
