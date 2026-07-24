import 'profile.dart';

class BulletinPhoto {
  const BulletinPhoto({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.roomId,
    this.challengeId,
    this.caption = '',
    this.createdAt,
    this.author,
    this.likeCount = 0,
    this.reviewCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String? roomId;
  final String? challengeId;
  final String caption;
  final DateTime? createdAt;
  final Profile? author;
  final int likeCount;
  final int reviewCount;
  final bool likedByMe;

  BulletinPhoto copyWith({
    Profile? author,
    int? likeCount,
    int? reviewCount,
    bool? likedByMe,
  }) {
    return BulletinPhoto(
      id: id,
      userId: userId,
      imageUrl: imageUrl,
      roomId: roomId,
      challengeId: challengeId,
      caption: caption,
      createdAt: createdAt,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      reviewCount: reviewCount ?? this.reviewCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory BulletinPhoto.fromJson(Map<String, dynamic> json) {
    return BulletinPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      roomId: json['room_id'] as String?,
      challengeId: json['challenge_id'] as String?,
      caption: json['caption'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      likeCount: json['like_count'] as int? ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'image_url': imageUrl,
        'room_id': roomId,
        'challenge_id': challengeId,
        'caption': caption,
      };
}

class BulletinReview {
  const BulletinReview({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.body,
    this.createdAt,
    this.author,
  });

  final String id;
  final String photoId;
  final String userId;
  final String body;
  final DateTime? createdAt;
  final Profile? author;

  factory BulletinReview.fromJson(Map<String, dynamic> json) {
    return BulletinReview(
      id: json['id'] as String,
      photoId: json['photo_id'] as String,
      userId: json['user_id'] as String,
      body: json['body'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'photo_id': photoId,
        'user_id': userId,
        'body': body,
      };
}
