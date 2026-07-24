import 'profile.dart';

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.clothesImageUrl,
    required this.walkVideoUrl,
    this.title = '',
    this.caption = '',
    this.walkThumbnailUrl,
    this.campaignId,
    this.groupId,
    this.isStarterPost = false,
    this.aspectRatio = '9:16',
    this.createdAt,
    this.author,
    this.likeCount = 0,
    this.repostCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.repostedByMe = false,
  });

  final String id;
  final String authorId;
  final String clothesImageUrl;
  final String walkVideoUrl;
  final String title;
  final String caption;
  final String? walkThumbnailUrl;
  final String? campaignId;
  final String? groupId;
  final bool isStarterPost;
  final String aspectRatio;
  final DateTime? createdAt;
  final Profile? author;
  final int likeCount;
  final int repostCount;
  final int commentCount;
  final bool likedByMe;
  final bool repostedByMe;

  Post copyWith({
    Profile? author,
    int? likeCount,
    int? repostCount,
    int? commentCount,
    bool? likedByMe,
    bool? repostedByMe,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      clothesImageUrl: clothesImageUrl,
      walkVideoUrl: walkVideoUrl,
      title: title,
      caption: caption,
      walkThumbnailUrl: walkThumbnailUrl,
      campaignId: campaignId,
      groupId: groupId,
      isStarterPost: isStarterPost,
      aspectRatio: aspectRatio,
      createdAt: createdAt,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      repostCount: repostCount ?? this.repostCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
      repostedByMe: repostedByMe ?? this.repostedByMe,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final stats = json['post_stats'] as Map<String, dynamic>?;
    return Post(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      clothesImageUrl: json['clothes_image_url'] as String,
      walkVideoUrl: json['walk_video_url'] as String,
      title: json['title'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      walkThumbnailUrl: json['walk_thumbnail_url'] as String?,
      campaignId: json['campaign_id'] as String?,
      groupId: json['group_id'] as String?,
      isStarterPost: json['is_starter_post'] as bool? ?? false,
      aspectRatio: json['aspect_ratio'] as String? ?? '9:16',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      author: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      likeCount: stats?['like_count'] as int? ??
          json['like_count'] as int? ??
          0,
      repostCount: stats?['repost_count'] as int? ??
          json['repost_count'] as int? ??
          0,
      commentCount: stats?['comment_count'] as int? ??
          json['comment_count'] as int? ??
          0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      repostedByMe: json['reposted_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'author_id': authorId,
        'clothes_image_url': clothesImageUrl,
        'walk_video_url': walkVideoUrl,
        'title': title,
        'caption': caption,
        'walk_thumbnail_url': walkThumbnailUrl,
        'campaign_id': campaignId,
        'group_id': groupId,
        'is_starter_post': isStarterPost,
        'aspect_ratio': aspectRatio,
      };
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.body,
    this.createdAt,
    this.author,
  });

  final String id;
  final String postId;
  final String userId;
  final String body;
  final DateTime? createdAt;
  final Profile? author;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
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
}
