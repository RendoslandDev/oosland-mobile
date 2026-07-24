import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/bulletin.dart';
import '../models/campaign.dart';
import '../models/challenge.dart';
import '../models/chat.dart';
import '../models/folder.dart';
import '../models/gift.dart';
import '../models/payout.dart';
import '../models/post.dart';
import '../models/profile.dart';

const _demoUserId = 'demo-user-001';

class DemoDataStore {
  DemoDataStore._();
  static final instance = DemoDataStore._();
  static const _uuid = Uuid();

  Profile? currentUser;
  bool isLoggedIn = false;
  final List<Profile> profiles = [];
  final List<Folder> folders = [];
  final List<FolderItem> folderItems = [];
  final List<Campaign> campaigns = [];
  final List<Group> groups = [];
  final List<Post> posts = [];
  final List<PostComment> comments = [];
  final Set<String> likes = {};
  final Set<String> reposts = {};
  final List<Gift> gifts = [];
  PostDraft? activeDraft;

  // Community / monetization feature collections.
  final List<MonthlyChallenge> challenges = [];
  final List<ChallengeEntry> challengeEntries = [];
  final List<ChatRoom> chatRooms = [];
  final List<ChatMessage> chatMessages = [];
  final Set<String> messageLikes = {}; // 'messageId:userId'
  final List<BulletinPhoto> bulletinPhotos = [];
  final List<BulletinReview> bulletinReviews = [];
  final Set<String> bulletinLikes = {}; // 'photoId:userId'
  final List<MonthlyPayout> payouts = [];

  final giftTypes = const [
    GiftType(id: 'rose', name: 'Rose', icon: '🌹', pointValue: 1),
    GiftType(id: 'crown', name: 'Crown', icon: '👑', pointValue: 5),
    GiftType(id: 'sparkle', name: 'Sparkle', icon: '✨', pointValue: 3),
  ];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('demo_store');
    if (saved != null) {
      _loadFromJson(jsonDecode(saved) as Map<String, dynamic>);
      return;
    }
    _seed();
    await _persist();
  }

  void _seed() {
    final demoProfile = Profile(
      id: _demoUserId,
      displayName: 'Demo Stylist',
      username: 'demo_stylist',
      bio: 'Fashion forward. Campaign ready.',
      role: UserRole.stylist,
      tier: UserTier.preCeleb,
      avatarUrl:
          'https://picsum.photos/seed/demo_stylist/200/200',
    );
    final celeb = Profile(
      id: 'demo-user-002',
      displayName: 'Runway Model',
      username: 'runway_model',
      bio: 'Walking the walk.',
      role: UserRole.model,
      tier: UserTier.celebrity,
      avatarUrl:
          'https://picsum.photos/seed/runway_model/200/200',
    );
    profiles.addAll([demoProfile, celeb]);
    currentUser = demoProfile;
    isLoggedIn = true;

    final folderId = _uuid.v4();
    folders.add(Folder(
      id: folderId,
      userId: _demoUserId,
      name: 'Runway Looks',
      description: 'Saved inspiration',
      coverUrl:
          'https://picsum.photos/seed/runway_looks/400/300',
    ));
    folderItems.add(FolderItem(
      id: _uuid.v4(),
      folderId: folderId,
      imageUrl:
          'https://picsum.photos/seed/evening_gown/400/300',
      caption: 'Evening gown inspo',
    ));

    final groupId = _uuid.v4();
    groups.add(Group(
      id: groupId,
      ownerId: _demoUserId,
      name: 'Best Dressed Club',
      description: 'Weekly style challenges',
    ));

    final campaignId = _uuid.v4();
    campaigns.add(Campaign(
      id: campaignId,
      creatorId: _demoUserId,
      title: 'Summer Street Style',
      theme: 'Streetwear',
      status: CampaignStatus.active,
      groupId: groupId,
      isStarterPost: true,
      startsAt: DateTime.now().subtract(const Duration(days: 2)),
      endsAt: DateTime.now().add(const Duration(days: 5)),
    ));

    posts.add(Post(
      id: _uuid.v4(),
      authorId: celeb.id,
      title: 'Golden Hour Walk',
      caption: 'Linen set for the challenge',
      clothesImageUrl:
          'https://picsum.photos/seed/golden_hour/600/400',
      walkVideoUrl:
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      campaignId: campaignId,
      groupId: groupId,
      isStarterPost: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      author: celeb,
      likeCount: 12,
      repostCount: 3,
      commentCount: 2,
    ));

    // --- Monthly challenge ---
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final challengeId = _uuid.v4();
    challenges.add(MonthlyChallenge(
      id: challengeId,
      month: monthStart,
      title: 'Monochrome Muse',
      theme: 'All-black & all-white editorial looks',
      description:
          'Style a head-to-toe monochrome outfit and walk it. Top likes share the creator fund.',
      coverUrl: 'https://picsum.photos/seed/monochrome_muse/800/500',
      prizePoolCents: 500000, // \$5,000 pool
      startsAt: monthStart,
      endsAt: monthEnd,
      createdAt: monthStart,
    ));
    challengeEntries.add(ChallengeEntry(
      id: _uuid.v4(),
      challengeId: challengeId,
      userId: celeb.id,
      postId: posts.first.id,
      createdAt: now.subtract(const Duration(hours: 3)),
    ));

    // --- Aesthetic chat room tied to the challenge ---
    final roomId = _uuid.v4();
    chatRooms.add(ChatRoom(
      id: roomId,
      ownerId: celeb.id,
      name: 'Monochrome Muse Lounge',
      groupId: groupId,
      challengeId: challengeId,
      description: 'Drop your looks, hype the best dressed.',
      coverUrl: 'https://picsum.photos/seed/muse_lounge/800/400',
      createdAt: now.subtract(const Duration(days: 1)),
      owner: celeb,
    ));
    chatMessages.addAll([
      ChatMessage(
        id: _uuid.v4(),
        roomId: roomId,
        userId: celeb.id,
        body: 'Welcome to the lounge! This month is monochrome — go bold. 🖤🤍',
        createdAt: now.subtract(const Duration(hours: 6)),
        author: celeb,
        likeCount: 4,
      ),
      ChatMessage(
        id: _uuid.v4(),
        roomId: roomId,
        userId: demoProfile.id,
        body: 'Just posted my all-white linen walk, feedback welcome!',
        createdAt: now.subtract(const Duration(hours: 2)),
        author: demoProfile,
        likeCount: 1,
      ),
    ]);

    // --- Bulletin space photos ---
    bulletinPhotos.add(BulletinPhoto(
      id: _uuid.v4(),
      userId: demoProfile.id,
      roomId: roomId,
      challengeId: challengeId,
      imageUrl: 'https://picsum.photos/seed/bulletin_white/500/700',
      caption: 'All-white fit check ☁️',
      createdAt: now.subtract(const Duration(hours: 1)),
      author: demoProfile,
      likeCount: 3,
    ));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_store', jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'currentUserId': currentUser?.id,
        'isLoggedIn': isLoggedIn,
        'profiles': profiles.map((p) => p.toJson()..['id'] = p.id).toList(),
        'folders': folders
            .map((f) => {
                  'id': f.id,
                  'user_id': f.userId,
                  'name': f.name,
                  'description': f.description,
                  'cover_url': f.coverUrl,
                })
            .toList(),
        'folderItems': folderItems
            .map((i) => {
                  'id': i.id,
                  'folder_id': i.folderId,
                  'image_url': i.imageUrl,
                  'caption': i.caption,
                  'sort_order': i.sortOrder,
                })
            .toList(),
        'campaigns': campaigns.map((c) => c.toJson()..['id'] = c.id).toList(),
        'groups': groups.map((g) => g.toJson()..['id'] = g.id).toList(),
        'posts': posts
            .map((p) => {
                  'id': p.id,
                  'author_id': p.authorId,
                  'title': p.title,
                  'caption': p.caption,
                  'clothes_image_url': p.clothesImageUrl,
                  'walk_video_url': p.walkVideoUrl,
                  'campaign_id': p.campaignId,
                  'group_id': p.groupId,
                  'is_starter_post': p.isStarterPost,
                  'created_at': p.createdAt?.toIso8601String(),
                })
            .toList(),
        'comments': comments
            .map((c) => {
                  'id': c.id,
                  'post_id': c.postId,
                  'user_id': c.userId,
                  'body': c.body,
                  'created_at': c.createdAt?.toIso8601String(),
                })
            .toList(),
        'likes': likes.toList(),
        'reposts': reposts.toList(),
        'gifts': gifts
            .map((g) => {
                  'id': g.id,
                  'sender_id': g.senderId,
                  'recipient_id': g.recipientId,
                  'gift_type': g.giftType,
                  'post_id': g.postId,
                  'room_id': g.roomId,
                  'message': g.message,
                  'created_at': g.createdAt?.toIso8601String(),
                })
            .toList(),
        'challenges': challenges
            .map((c) => {
                  'id': c.id,
                  'month': c.month.toIso8601String(),
                  'title': c.title,
                  'theme': c.theme,
                  'description': c.description,
                  'cover_url': c.coverUrl,
                  'prize_pool_cents': c.prizePoolCents,
                  'starts_at': c.startsAt?.toIso8601String(),
                  'ends_at': c.endsAt?.toIso8601String(),
                  'created_at': c.createdAt?.toIso8601String(),
                })
            .toList(),
        'challengeEntries': challengeEntries
            .map((e) => {
                  'id': e.id,
                  'challenge_id': e.challengeId,
                  'user_id': e.userId,
                  'post_id': e.postId,
                  'created_at': e.createdAt?.toIso8601String(),
                })
            .toList(),
        'chatRooms': chatRooms
            .map((r) => {
                  'id': r.id,
                  'owner_id': r.ownerId,
                  'name': r.name,
                  'group_id': r.groupId,
                  'challenge_id': r.challengeId,
                  'description': r.description,
                  'cover_url': r.coverUrl,
                  'created_at': r.createdAt?.toIso8601String(),
                })
            .toList(),
        'chatMessages': chatMessages
            .map((m) => {
                  'id': m.id,
                  'room_id': m.roomId,
                  'user_id': m.userId,
                  'parent_id': m.parentId,
                  'body': m.body,
                  'created_at': m.createdAt?.toIso8601String(),
                })
            .toList(),
        'messageLikes': messageLikes.toList(),
        'bulletinPhotos': bulletinPhotos
            .map((p) => {
                  'id': p.id,
                  'user_id': p.userId,
                  'room_id': p.roomId,
                  'challenge_id': p.challengeId,
                  'image_url': p.imageUrl,
                  'caption': p.caption,
                  'created_at': p.createdAt?.toIso8601String(),
                })
            .toList(),
        'bulletinReviews': bulletinReviews
            .map((r) => {
                  'id': r.id,
                  'photo_id': r.photoId,
                  'user_id': r.userId,
                  'body': r.body,
                  'created_at': r.createdAt?.toIso8601String(),
                })
            .toList(),
        'bulletinLikes': bulletinLikes.toList(),
        'payouts': payouts
            .map((p) => {
                  'user_id': p.userId,
                  'month': p.month.toIso8601String(),
                  'like_count': p.likeCount,
                  'pool_cents': p.poolCents,
                  'payout_cents': p.payoutCents,
                  'computed_at': p.computedAt?.toIso8601String(),
                })
            .toList(),
      };

  void _loadFromJson(Map<String, dynamic> json) {
    isLoggedIn = json['isLoggedIn'] as bool? ?? false;
    profiles
      ..clear()
      ..addAll(
        (json['profiles'] as List<dynamic>? ?? [])
            .map((e) => Profile.fromJson(e as Map<String, dynamic>)),
      );
    final currentId = json['currentUserId'] as String?;
    currentUser = profiles.cast<Profile?>().firstWhere(
          (p) => p?.id == currentId,
          orElse: () => profiles.isNotEmpty ? profiles.first : null,
        );
    folders
      ..clear()
      ..addAll(
        (json['folders'] as List<dynamic>? ?? [])
            .map((e) => Folder.fromJson(e as Map<String, dynamic>)),
      );
    folderItems
      ..clear()
      ..addAll(
        (json['folderItems'] as List<dynamic>? ?? [])
            .map((e) => FolderItem.fromJson(e as Map<String, dynamic>)),
      );
    campaigns
      ..clear()
      ..addAll(
        (json['campaigns'] as List<dynamic>? ?? [])
            .map((e) => Campaign.fromJson(e as Map<String, dynamic>)),
      );
    groups
      ..clear()
      ..addAll(
        (json['groups'] as List<dynamic>? ?? [])
            .map((e) => Group.fromJson(e as Map<String, dynamic>)),
      );
    posts
      ..clear()
      ..addAll(
        (json['posts'] as List<dynamic>? ?? []).map((e) {
          final map = e as Map<String, dynamic>;
          final author = profiles.firstWhere(
            (p) => p.id == map['author_id'],
            orElse: () => profiles.first,
          );
          return Post.fromJson(map).copyWith(
            author: author,
            likeCount: likes.where((k) => k.startsWith('${map['id']}:')).length,
          );
        }),
      );
    likes
      ..clear()
      ..addAll((json['likes'] as List<dynamic>? ?? []).cast<String>());
    reposts
      ..clear()
      ..addAll((json['reposts'] as List<dynamic>? ?? []).cast<String>());
    gifts
      ..clear()
      ..addAll(
        (json['gifts'] as List<dynamic>? ?? []).map((e) {
          final map = e as Map<String, dynamic>;
          return Gift(
            id: map['id'] as String,
            senderId: map['sender_id'] as String,
            recipientId: map['recipient_id'] as String,
            giftType: map['gift_type'] as String,
            postId: map['post_id'] as String?,
            roomId: map['room_id'] as String?,
            message: map['message'] as String? ?? '',
            createdAt: map['created_at'] != null
                ? DateTime.parse(map['created_at'] as String)
                : null,
            giftTypeData: giftTypes.firstWhere(
              (t) => t.id == map['gift_type'],
              orElse: () => giftTypes.first,
            ),
          );
        }),
      );
    challenges
      ..clear()
      ..addAll(
        (json['challenges'] as List<dynamic>? ?? [])
            .map((e) => MonthlyChallenge.fromJson(e as Map<String, dynamic>)),
      );
    challengeEntries
      ..clear()
      ..addAll(
        (json['challengeEntries'] as List<dynamic>? ?? [])
            .map((e) => ChallengeEntry.fromJson(e as Map<String, dynamic>)),
      );
    chatRooms
      ..clear()
      ..addAll(
        (json['chatRooms'] as List<dynamic>? ?? [])
            .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>)),
      );
    chatMessages
      ..clear()
      ..addAll(
        (json['chatMessages'] as List<dynamic>? ?? [])
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)),
      );
    messageLikes
      ..clear()
      ..addAll((json['messageLikes'] as List<dynamic>? ?? []).cast<String>());
    bulletinPhotos
      ..clear()
      ..addAll(
        (json['bulletinPhotos'] as List<dynamic>? ?? [])
            .map((e) => BulletinPhoto.fromJson(e as Map<String, dynamic>)),
      );
    bulletinReviews
      ..clear()
      ..addAll(
        (json['bulletinReviews'] as List<dynamic>? ?? [])
            .map((e) => BulletinReview.fromJson(e as Map<String, dynamic>)),
      );
    bulletinLikes
      ..clear()
      ..addAll((json['bulletinLikes'] as List<dynamic>? ?? []).cast<String>());
    payouts
      ..clear()
      ..addAll(
        (json['payouts'] as List<dynamic>? ?? [])
            .map((e) => MonthlyPayout.fromJson(e as Map<String, dynamic>)),
      );
  }

  Profile? profileById(String id) {
    try {
      return profiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  String newId() => _uuid.v4();

  Future<void> save() => _persist();
}

final demoStoreProvider = Provider<DemoDataStore>((ref) {
  return DemoDataStore.instance;
});

final demoInitializedProvider = FutureProvider<bool>((ref) async {
  await DemoDataStore.instance.initialize();
  return true;
});
