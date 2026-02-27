import 'dart:math';

/// Represents a reminder with optional recurrence.
class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final bool isRecurring;
  final RecurrenceType? recurrenceType;
  final bool isCompleted;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isRecurring = false,
    this.recurrenceType,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Reminder.create({
    required String title,
    String? description,
    required DateTime dueDate,
    bool isRecurring = false,
    RecurrenceType? recurrenceType,
  }) {
    return Reminder(
      id: _generateId(),
      title: title,
      description: description,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurrenceType: recurrenceType,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceType: json['recurrence_type'] != null
          ? RecurrenceType.values.firstWhere(
              (e) => e.name == json['recurrence_type'],
              orElse: () => RecurrenceType.daily,
            )
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType?.name,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    bool? isCompleted,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  bool get isDueThisWeek {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));
    return dueDate.isAfter(now) && dueDate.isBefore(weekEnd);
  }

  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return '${now.toRadixString(36)}_${random.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reminder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum RecurrenceType {
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }
}
