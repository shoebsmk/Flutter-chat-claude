import 'package:flutter/foundation.dart';
import '../utils/date_utils.dart';

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

  /// Type of message: 'text', 'image', 'file', etc.
  final String messageType;

  /// URL to the attached file (if any).
  final String? fileUrl;

  /// Original filename of the attached file (if any).
  final String? fileName;

  /// Size of the attached file in bytes (if any).
  final int? fileSize;

  const Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.deletedAt,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSize,
  });

  /// Creates a Message from a Supabase JSON response.
  factory Message.fromJson(Map<String, dynamic> json) {
    // Use AppDateUtils for consistent date parsing across the app
    // parseOrDefault ensures we have a valid DateTime even if parsing fails
    // However, if created_at is missing, this indicates a data issue that should be logged
    final createdAtValue = json['created_at'];
    final parsedDate = AppDateUtils.parse(createdAtValue);
    final createdAt = parsedDate ?? DateTime.now();
    
    // Log warning if created_at was missing or couldn't be parsed
    if (createdAtValue == null) {
      debugPrint('Warning: Message missing created_at timestamp. Using current time as fallback.');
    } else if (parsedDate == null) {
      debugPrint('Warning: Message created_at could not be parsed: $createdAtValue');
    }

    return Message(
      id: json['id']?.toString(),
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: createdAt,
      deletedAt: AppDateUtils.parse(json['deleted_at']),
      messageType: json['message_type']?.toString() ?? 'text',
      fileUrl: json['file_url']?.toString(),
      fileName: json['file_name']?.toString(),
      fileSize: json['file_size'] as int?,
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
      'message_type': messageType,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
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
    String? messageType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
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

  /// Returns true if this message contains an image attachment.
  bool get hasImage => messageType == 'image' && fileUrl != null;

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
