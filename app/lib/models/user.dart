class AppUser {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final bool online;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.online = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    return AppUser(
      id: j['id'] as String,
      username: j['username'] as String,
      email: j['email'] as String? ?? '',
      displayName: j['display_name'] as String? ?? j['username'] as String? ?? '',
      avatarUrl: j['avatar_url'] as String?,
      bio: j['bio'] as String?,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
      online: j['online'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'bio': bio,
        'online': online,
      };

  AppUser copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? online,
  }) {
    return AppUser(
      id: id,
      username: username,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      online: online ?? this.online,
    );
  }
}
