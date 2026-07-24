import 'profile.dart';

class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.ownerId,
    required this.name,
    this.groupId,
    this.challengeId,
    this.description = '',
    this.coverUrl,
    this.createdAt,
    this.owner,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? groupId;
  final String? challengeId;
  final String description;
  final String? coverUrl;
  final DateTime? createdAt;
  final Profile? owner;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      groupId: json['group_id'] as String?,
      challengeId: json['challenge_id'] as String?,
      description: json['description'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      owner: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'name': name,
        'group_id': groupId,
        'challenge_id': challengeId,
        'description': description,
        'cover_url': coverUrl,
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.body,
    this.parentId,
    this.createdAt,
    this.author,
    this.likeCount = 0,
    this.replyCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String roomId;
  final String userId;
  final String body;
  final String? parentId;
  final DateTime? createdAt;
  final Profile? author;
  final int likeCount;
  final int replyCount;
  final bool likedByMe;

  ChatMessage copyWith({
    Profile? author,
    int? likeCount,
    int? replyCount,
    bool? likedByMe,
  }) {
    return ChatMessage(
      id: id,
      roomId: roomId,
      userId: userId,
      body: body,
      parentId: parentId,
      createdAt: createdAt,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      parentId: json['parent_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      likeCount: json['like_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'user_id': userId,
        'body': body,
        'parent_id': parentId,
      };
}
