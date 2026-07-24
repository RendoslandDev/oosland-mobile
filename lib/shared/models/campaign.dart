enum CampaignStatus { draft, active, ended }

class Campaign {
  const Campaign({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description = '',
    this.theme = '',
    this.startsAt,
    this.endsAt,
    this.status = CampaignStatus.draft,
    this.coverUrl,
    this.groupId,
    this.isStarterPost = false,
    this.createdAt,
  });

  final String id;
  final String creatorId;
  final String title;
  final String description;
  final String theme;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final CampaignStatus status;
  final String? coverUrl;
  final String? groupId;
  final bool isStarterPost;
  final DateTime? createdAt;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      status: CampaignStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CampaignStatus.draft,
      ),
      coverUrl: json['cover_url'] as String?,
      groupId: json['group_id'] as String?,
      isStarterPost: json['is_starter_post'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'creator_id': creatorId,
        'title': title,
        'description': description,
        'theme': theme,
        'starts_at': startsAt?.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'status': status.name,
        'cover_url': coverUrl,
        'group_id': groupId,
        'is_starter_post': isStarterPost,
      };
}

class Group {
  const Group({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description = '',
    this.isPublic = true,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final bool isPublic;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isPublic: json['is_public'] as bool? ?? true,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'is_public': isPublic,
        'avatar_url': avatarUrl,
      };
}

class PostDraft {
  const PostDraft({
    required this.id,
    required this.authorId,
    required this.clothesImageUrl,
    this.caption = '',
    this.campaignId,
    this.groupId,
    this.startNewCampaign = false,
    this.updatedAt,
  });

  final String id;
  final String authorId;
  final String clothesImageUrl;
  final String caption;
  final String? campaignId;
  final String? groupId;
  final bool startNewCampaign;
  final DateTime? updatedAt;

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      clothesImageUrl: json['clothes_image_url'] as String,
      caption: json['caption'] as String? ?? '',
      campaignId: json['campaign_id'] as String?,
      groupId: json['group_id'] as String?,
      startNewCampaign: json['start_new_campaign'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
