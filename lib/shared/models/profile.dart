enum UserRole { stylist, model, designer, gifter, fan }

enum UserTier { standard, preCeleb, celebrity }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.stylist => 'Stylist',
        UserRole.model => 'Model',
        UserRole.designer => 'Designer',
        UserRole.gifter => 'Gifter',
        UserRole.fan => 'Fan',
      };

  String get dbValue => name;

  static UserRole fromDb(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value.replaceAll('_', ''),
      orElse: () => UserRole.fan,
    );
  }
}

extension UserTierX on UserTier {
  String get label => switch (this) {
        UserTier.standard => '',
        UserTier.preCeleb => 'Pre-celeb',
        UserTier.celebrity => 'Celebrity',
      };

  String get dbValue => switch (this) {
        UserTier.standard => 'standard',
        UserTier.preCeleb => 'pre_celeb',
        UserTier.celebrity => 'celebrity',
      };

  static UserTier fromDb(String value) {
    return switch (value) {
      'pre_celeb' => UserTier.preCeleb,
      'celebrity' => UserTier.celebrity,
      _ => UserTier.standard,
    };
  }
}

class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.username,
    this.bio = '',
    this.avatarUrl,
    this.role = UserRole.fan,
    this.tier = UserTier.standard,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String username;
  final String bio;
  final String? avatarUrl;
  final UserRole role;
  final UserTier tier;
  final DateTime? createdAt;

  Profile copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    UserRole? role,
    UserTier? tier,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      tier: tier ?? this.tier,
      createdAt: createdAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: UserRoleX.fromDb(json['role'] as String? ?? 'fan'),
      tier: UserTierX.fromDb(json['tier'] as String? ?? 'standard'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'username': username,
        'bio': bio,
        'avatar_url': avatarUrl,
        'role': role.dbValue,
        'tier': tier.dbValue,
      };
}
