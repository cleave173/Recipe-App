class User {
  final int id;
  final String? uid; // Firebase UID
  final String username;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool isBlocked;
  final String? avatarUrl;

  User({
    required this.id,
    this.uid,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isBlocked = false,
    this.avatarUrl,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
  bool get isUser => role.toUpperCase() == 'USER';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      uid: json['uid'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      isBlocked: json['is_blocked'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'is_blocked': isBlocked,
      'avatar_url': avatarUrl,
    };
  }

  User copyWith({
    int? id,
    String? uid,
    String? username,
    String? email,
    String? role,
    DateTime? createdAt,
    bool? isBlocked,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, role: $role)';
  }
}
