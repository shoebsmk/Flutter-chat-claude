/// Represents a chat message between two users.
class Message {
  /// Unique identifier for the message.
  final String? id;

  /// ID of the user who sent the message.
  final String senderId;

  /// ID of the user who receives the message.
  final String receiverId;

  /// The message content/text.
  final String content;

  /// Whether the message has been read by the receiver.
  final bool isRead;

  /// When the message was created.
  final DateTime createdAt;

  /// When the message was deleted (null if not deleted).
  final DateTime? deletedAt;

  const Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.deletedAt,
  });

  /// Creates a Message from a Supabase JSON response.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString(),
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      deletedAt: _parseDateTime(json['deleted_at']),
    );
  }

  /// Converts the Message to a JSON map for Supabase insert.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': isRead,
    };
  }

  /// Creates a copy of this Message with the given fields replaced.
  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Parses a DateTime from various formats.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Returns true if this message was sent by the given user ID.
  bool isSentBy(String userId) => senderId == userId;

  /// Returns true if this message was received by the given user ID.
  bool isReceivedBy(String userId) => receiverId == userId;

  /// Returns the ID of the other user in this conversation.
  String getOtherUserId(String currentUserId) {
    return senderId == currentUserId ? receiverId : senderId;
  }

  /// Returns true if this message has been deleted.
  bool get isDeleted => deletedAt != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, from: $senderId, to: $receiverId, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content})';
  }
}
