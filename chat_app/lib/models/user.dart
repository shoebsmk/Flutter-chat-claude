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

  /// Last time the user was seen online.
  final DateTime? lastSeen;

  /// URL of the user's profile picture.
  final String? avatarUrl;

  /// Bio/description of the user.
  final String? bio;

  /// When the user's profile was last updated.
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.username,
    this.email,
    this.createdAt,
    this.lastSeen,
    this.avatarUrl,
    this.bio,
    this.updatedAt,
  });

  /// Creates a User from a Supabase JSON response.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      email: json['email']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      lastSeen: _parseDateTime(json['last_seen']),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts the User to a JSON map for Supabase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (email != null) 'email': email,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this User with the given fields replaced.
  User copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? avatarUrl,
    String? bio,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      updatedAt: updatedAt ?? this.updatedAt,
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

  /// Returns true if the user is considered online (last seen within 1 minute).
  bool get isOnline {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inMinutes < 1;
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, lastSeen: $lastSeen, avatarUrl: $avatarUrl, bio: $bio)';
  }
}
