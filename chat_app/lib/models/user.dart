/// Represents a user in the chat application.
class User {
  /// Unique identifier for the user (from Supabase auth).
  final String id;

  /// Display name of the user.
  final String username;

  /// Email address of the user (optional, may not be exposed).
  final String? email;

  /// When the user was created.
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.createdAt,
  });

  /// Creates a User from a Supabase JSON response.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  /// Converts the User to a JSON map for Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this User with the given fields replaced.
  User copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Parses a DateTime from various formats.
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email)';
  }
}
