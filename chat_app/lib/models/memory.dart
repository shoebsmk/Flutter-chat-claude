import 'dart:math';

/// Represents a saved memory/note in the personal knowledge base.
class Memory {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memory({
    required this.id,
    required this.title,
    required this.content,
    this.tags = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Memory.create({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    return Memory(
      id: _generateId(),
      title: title,
      content: content,
      tags: tags,
      isPinned: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isPinned: json['is_pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Memory copyWith({
    String? title,
    String? content,
    List<String>? tags,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Memory(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999);
    return '${now.toRadixString(36)}_${random.toRadixString(36)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Memory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
