class Folder {
  const Folder({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    this.coverUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final String? coverUrl;
  final DateTime? createdAt;

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      coverUrl: json['cover_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'description': description,
        'cover_url': coverUrl,
      };
}

class FolderItem {
  const FolderItem({
    required this.id,
    required this.folderId,
    required this.imageUrl,
    this.caption = '',
    this.sortOrder = 0,
    this.createdAt,
  });

  final String id;
  final String folderId;
  final String imageUrl;
  final String caption;
  final int sortOrder;
  final DateTime? createdAt;

  factory FolderItem.fromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'] as String,
      folderId: json['folder_id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'folder_id': folderId,
        'image_url': imageUrl,
        'caption': caption,
        'sort_order': sortOrder,
      };
}
