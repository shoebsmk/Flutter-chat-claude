import 'dart:math';

/// Represents a task list (to-do, shopping, ideas, etc.).
class TaskList {
  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskItem> items;

  const TaskList({
    required this.id,
    required this.name,
    this.emoji = '📝',
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory TaskList.create({
    required String name,
    String emoji = '📝',
  }) {
    final now = DateTime.now();
    return TaskList(
      id: _generateId(),
      name: name,
      emoji: emoji,
      createdAt: now,
      updatedAt: now,
      items: [],
    );
  }

  factory TaskList.fromJson(Map<String, dynamic> json) {
    return TaskList(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📝',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  TaskList copyWith({
    String? name,
    String? emoji,
    DateTime? updatedAt,
    List<TaskItem>? items,
  }) {
    return TaskList(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      items: items ?? this.items,
    );
  }

  int get totalItems => items.length;
  int get completedItems => items.where((i) => i.isCompleted).length;
  int get pendingItems => totalItems - completedItems;

  double get completionPercentage =>
      totalItems == 0 ? 0 : completedItems / totalItems;

  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return '${now.toRadixString(36)}_${random.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TaskList && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single item within a task list.
class TaskItem {
  final String id;
  final String content;
  final bool isCompleted;
  final int position;
  final DateTime createdAt;

  const TaskItem({
    required this.id,
    required this.content,
    this.isCompleted = false,
    this.position = 0,
    required this.createdAt,
  });

  factory TaskItem.create({
    required String content,
    int position = 0,
  }) {
    return TaskItem(
      id: _generateId(),
      content: content,
      isCompleted: false,
      position: position,
      createdAt: DateTime.now(),
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      content: json['content'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      position: json['position'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_completed': isCompleted,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskItem copyWith({
    String? content,
    bool? isCompleted,
    int? position,
  }) {
    return TaskItem(
      id: id,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt,
    );
  }

  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return '${now.toRadixString(36)}_${random.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TaskItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
