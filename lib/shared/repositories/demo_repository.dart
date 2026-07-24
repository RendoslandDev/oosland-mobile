import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_store.dart';
import '../models/bulletin.dart';
import '../models/campaign.dart';
import '../models/challenge.dart';
import '../models/chat.dart';
import '../models/folder.dart';
import '../models/gift.dart';
import '../models/payout.dart';
import '../models/post.dart';
import '../models/profile.dart';
import 'app_repository.dart';

class DemoRepository implements AppRepository {
  DemoRepository(this.ref);

  final Ref ref;
  final _authController = StreamController<Profile?>.broadcast();
  final _roomControllers = <String, StreamController<List<ChatMessage>>>{};

  DemoDataStore get _store => DemoDataStore.instance;

  @override
  Future<void> initialize() async {
    await _store.initialize();
    _authController.add(_store.currentUser);
  }

  @override
  bool get isAuthenticated => _store.isLoggedIn;

  @override
  Profile? get currentProfile => _store.currentUser;

  @override
  Stream<Profile?> get authStateChanges => _authController.stream;

  @override
  Future<Profile?> signIn({
    required String email,
    required String password,
  }) async {
    _store.isLoggedIn = true;
    _store.currentUser ??= _store.profiles.first;
    await _store.save();
    _authController.add(_store.currentUser);
    return _store.currentUser;
  }

  @override
  Future<Profile?> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final profile = Profile(
      id: _store.newId(),
      displayName: displayName,
      username: username,
      role: UserRole.fan,
    );
    _store.profiles.add(profile);
    _store.currentUser = profile;
    _store.isLoggedIn = true;
    await _store.save();
    _authController.add(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    _store.isLoggedIn = false;
    await _store.save();
    _authController.add(null);
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final index = _store.profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _store.profiles[index] = profile;
    }
    _store.currentUser = profile;
    await _store.save();
    _authController.add(profile);
    return profile;
  }

  @override
  Future<List<Folder>> getFolders() async {
    final userId = _store.currentUser?.id;
    if (userId == null) return [];
    return _store.folders.where((f) => f.userId == userId).toList();
  }

  @override
  Future<Folder> createFolder({
    required String name,
    String description = '',
  }) async {
    final userId = _store.currentUser!.id;
    final folder = Folder(
      id: _store.newId(),
      userId: userId,
      name: name,
      description: description,
    );
    _store.folders.add(folder);
    await _store.save();
    return folder;
  }

  @override
  Future<void> deleteFolder(String id) async {
    _store.folders.removeWhere((f) => f.id == id);
    _store.folderItems.removeWhere((i) => i.folderId == id);
    await _store.save();
  }

  @override
  Future<List<FolderItem>> getFolderItems(String folderId) async {
    return _store.folderItems
        .where((i) => i.folderId == folderId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<FolderItem> addFolderItem({
    required String folderId,
    required String imageUrl,
    String caption = '',
  }) async {
    final item = FolderItem(
      id: _store.newId(),
      folderId: folderId,
      imageUrl: imageUrl,
      caption: caption,
      sortOrder: _store.folderItems.where((i) => i.folderId == folderId).length,
    );
    _store.folderItems.add(item);
    await _store.save();
    return item;
  }

  @override
  Future<List<Campaign>> getCampaigns() async {
    return List.from(_store.campaigns)
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
  }

  @override
  Future<List<Group>> getGroups() async {
    return List.from(_store.groups);
  }

  @override
  Future<Campaign> createCampaign({
    required String title,
    required String theme,
    String? groupId,
    bool isStarterPost = false,
  }) async {
    final campaign = Campaign(
      id: _store.newId(),
      creatorId: _store.currentUser!.id,
      title: title,
      theme: theme,
      status: CampaignStatus.active,
      groupId: groupId,
      isStarterPost: isStarterPost,
      startsAt: DateTime.now(),
      endsAt: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
    );
    _store.campaigns.add(campaign);
    await _store.save();
    return campaign;
  }

  @override
  Future<Group> createGroup({
    required String name,
    String description = '',
  }) async {
    final group = Group(
      id: _store.newId(),
      ownerId: _store.currentUser!.id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
    );
    _store.groups.add(group);
    await _store.save();
    return group;
  }

  @override
  Future<PostDraft?> getActiveDraft() async => _store.activeDraft;

  @override
  Future<PostDraft> saveDraftPhase1({
    required String clothesImageUrl,
    String caption = '',
    bool startNewCampaign = false,
  }) async {
    final draft = PostDraft(
      id: _store.activeDraft?.id ?? _store.newId(),
      authorId: _store.currentUser!.id,
      clothesImageUrl: clothesImageUrl,
      caption: caption,
      startNewCampaign: startNewCampaign,
      updatedAt: DateTime.now(),
    );
    _store.activeDraft = draft;
    await _store.save();
    return draft;
  }

  @override
  Future<void> clearDraft() async {
    _store.activeDraft = null;
    await _store.save();
  }

  @override
  Future<Post> publishPost({
    required String clothesImageUrl,
    required String walkVideoUrl,
    required String title,
    String caption = '',
    bool startNewCampaign = false,
    String? campaignId,
    String? groupId,
  }) async {
    final user = _store.currentUser!;
    String? resolvedCampaignId = campaignId;
    String? resolvedGroupId = groupId;

    if (startNewCampaign) {
      final group = await createGroup(
        name: title,
        description: caption,
      );
      resolvedGroupId = group.id;
      final campaign = await createCampaign(
        title: title,
        theme: title,
        groupId: group.id,
        isStarterPost: true,
      );
      resolvedCampaignId = campaign.id;
    }

    final post = Post(
      id: _store.newId(),
      authorId: user.id,
      title: title,
      caption: caption,
      clothesImageUrl: clothesImageUrl,
      walkVideoUrl: walkVideoUrl,
      campaignId: resolvedCampaignId,
      groupId: resolvedGroupId,
      isStarterPost: startNewCampaign,
      createdAt: DateTime.now(),
      author: user,
    );
    _store.posts.insert(0, post);
    _store.activeDraft = null;
    await _store.save();
    return post;
  }

  Post _hydratePost(Post post) {
    final userId = _store.currentUser?.id;
    final likeKey = '${post.id}:$userId';
    final liked = userId != null && _store.likes.contains(likeKey);
    final reposted =
        userId != null && _store.reposts.contains('${post.id}:$userId');
    final likeCount =
        _store.likes.where((k) => k.startsWith('${post.id}:')).length;
    final repostCount =
        _store.reposts.where((k) => k.startsWith('${post.id}:')).length;
    final commentCount =
        _store.comments.where((c) => c.postId == post.id).length;
    return post.copyWith(
      author: _store.profileById(post.authorId),
      likeCount: likeCount,
      repostCount: repostCount,
      commentCount: commentCount,
      likedByMe: liked,
      repostedByMe: reposted,
    );
  }

  @override
  Future<List<Post>> getFeedPosts() async {
    return _store.posts.map(_hydratePost).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  }

  @override
  Future<Post?> getPost(String id) async {
    try {
      final post = _store.posts.firstWhere((p) => p.id == id);
      return _hydratePost(post);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PostComment>> getComments(String postId) async {
    return _store.comments
        .where((c) => c.postId == postId)
        .map((c) => PostComment(
              id: c.id,
              postId: c.postId,
              userId: c.userId,
              body: c.body,
              createdAt: c.createdAt,
              author: _store.profileById(c.userId),
            ))
        .toList()
      ..sort((a, b) =>
          (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
  }

  @override
  Future<void> toggleLike(String postId) async {
    final userId = _store.currentUser!.id;
    final key = '$postId:$userId';
    if (_store.likes.contains(key)) {
      _store.likes.remove(key);
    } else {
      _store.likes.add(key);
    }
    await _store.save();
  }

  @override
  Future<void> toggleRepost(String postId) async {
    final userId = _store.currentUser!.id;
    final key = '$postId:$userId';
    if (_store.reposts.contains(key)) {
      _store.reposts.remove(key);
    } else {
      _store.reposts.add(key);
    }
    await _store.save();
  }

  @override
  Future<PostComment> addComment(String postId, String body) async {
    final comment = PostComment(
      id: _store.newId(),
      postId: postId,
      userId: _store.currentUser!.id,
      body: body,
      createdAt: DateTime.now(),
      author: _store.currentUser,
    );
    _store.comments.add(comment);
    await _store.save();
    return comment;
  }

  @override
  Future<List<GiftType>> getGiftTypes() async => _store.giftTypes;

  @override
  Future<List<Gift>> getReceivedGifts([String? userId]) async {
    final id = userId ?? _store.currentUser?.id;
    if (id == null) return [];
    return _store.gifts
        .where((g) => g.recipientId == id)
        .toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
  }

  @override
  Future<Gift> sendGift({
    required String recipientId,
    required String giftType,
    String? postId,
    String? roomId,
    String message = '',
  }) async {
    final gift = Gift(
      id: _store.newId(),
      senderId: _store.currentUser!.id,
      recipientId: recipientId,
      giftType: giftType,
      postId: postId,
      roomId: roomId,
      message: message,
      createdAt: DateTime.now(),
      sender: _store.currentUser,
      recipient: _store.profileById(recipientId),
      giftTypeData: _store.giftTypes.firstWhere((t) => t.id == giftType),
    );
    _store.gifts.add(gift);
    await _store.save();
    return gift;
  }

  // --- Monthly challenge engine ---

  @override
  Future<MonthlyChallenge?> getCurrentChallenge() async {
    final now = DateTime.now();
    final userId = _store.currentUser?.id;
    MonthlyChallenge? current;
    for (final c in _store.challenges) {
      final inWindow = (c.startsAt == null || !c.startsAt!.isAfter(now)) &&
          (c.endsAt == null || !c.endsAt!.isBefore(now));
      if (inWindow) {
        current = c;
        break;
      }
    }
    if (current == null) return null;
    final entries =
        _store.challengeEntries.where((e) => e.challengeId == current!.id);
    return current.copyWith(
      entryCount: entries.length,
      enteredByMe: userId != null && entries.any((e) => e.userId == userId),
    );
  }

  @override
  Future<void> enterChallenge(String challengeId, {String? postId}) async {
    final userId = _store.currentUser!.id;
    final exists = _store.challengeEntries.any((e) =>
        e.challengeId == challengeId &&
        e.userId == userId &&
        e.postId == postId);
    if (exists) return;
    _store.challengeEntries.add(ChallengeEntry(
      id: _store.newId(),
      challengeId: challengeId,
      userId: userId,
      postId: postId,
      createdAt: DateTime.now(),
    ));
    await _store.save();
  }

  // --- Aesthetic chat ---

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    return _store.chatRooms
        .map((r) => ChatRoom(
              id: r.id,
              ownerId: r.ownerId,
              name: r.name,
              groupId: r.groupId,
              challengeId: r.challengeId,
              description: r.description,
              coverUrl: r.coverUrl,
              createdAt: r.createdAt,
              owner: _store.profileById(r.ownerId),
            ))
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
  }

  @override
  Future<ChatRoom?> getChatRoom(String id) async {
    final rooms = await getChatRooms();
    try {
      return rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ChatRoom> getOrCreateRoom({
    required String ownerId,
    String? name,
    String? challengeId,
  }) async {
    final existing = _store.chatRooms
        .where((r) => r.ownerId == ownerId)
        .cast<ChatRoom?>()
        .firstWhere((_) => true, orElse: () => null);
    if (existing != null) {
      return (await getChatRoom(existing.id))!;
    }
    final owner = _store.profileById(ownerId);
    final room = ChatRoom(
      id: _store.newId(),
      ownerId: ownerId,
      name: name ?? '${owner?.displayName ?? 'Creator'} Lounge',
      challengeId: challengeId,
      createdAt: DateTime.now(),
      owner: owner,
    );
    _store.chatRooms.add(room);
    await _store.save();
    return room;
  }

  ChatMessage _hydrateMessage(ChatMessage m) {
    final userId = _store.currentUser?.id;
    final likeCount =
        _store.messageLikes.where((k) => k.startsWith('${m.id}:')).length;
    final replyCount =
        _store.chatMessages.where((r) => r.parentId == m.id).length;
    return m.copyWith(
      author: _store.profileById(m.userId),
      likeCount: likeCount == 0 ? m.likeCount : likeCount,
      replyCount: replyCount,
      likedByMe: userId != null && _store.messageLikes.contains('${m.id}:$userId'),
    );
  }

  List<ChatMessage> _roomMessages(String roomId) {
    return _store.chatMessages
        .where((m) => m.roomId == roomId && m.parentId == null)
        .map(_hydrateMessage)
        .toList()
      ..sort((a, b) => (a.createdAt ?? DateTime.now())
          .compareTo(b.createdAt ?? DateTime.now()));
  }

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async =>
      _roomMessages(roomId);

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    final controller = _roomControllers.putIfAbsent(
      roomId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    // Emit current snapshot on the next microtask so listeners receive it.
    scheduleMicrotask(() => controller.add(_roomMessages(roomId)));
    return controller.stream;
  }

  void _emitRoom(String roomId) {
    _roomControllers[roomId]?.add(_roomMessages(roomId));
  }

  @override
  Future<ChatMessage> sendMessage(String roomId, String body,
      {String? parentId}) async {
    final message = ChatMessage(
      id: _store.newId(),
      roomId: roomId,
      userId: _store.currentUser!.id,
      body: body,
      parentId: parentId,
      createdAt: DateTime.now(),
      author: _store.currentUser,
    );
    _store.chatMessages.add(message);
    await _store.save();
    _emitRoom(roomId);
    return _hydrateMessage(message);
  }

  @override
  Future<void> toggleMessageLike(String messageId) async {
    final userId = _store.currentUser!.id;
    final key = '$messageId:$userId';
    if (_store.messageLikes.contains(key)) {
      _store.messageLikes.remove(key);
    } else {
      _store.messageLikes.add(key);
    }
    await _store.save();
    final msg = _store.chatMessages
        .cast<ChatMessage?>()
        .firstWhere((m) => m?.id == messageId, orElse: () => null);
    if (msg != null) _emitRoom(msg.roomId);
  }

  // --- Bulletin space ---

  BulletinPhoto _hydratePhoto(BulletinPhoto p) {
    final userId = _store.currentUser?.id;
    final likeCount =
        _store.bulletinLikes.where((k) => k.startsWith('${p.id}:')).length;
    final reviewCount =
        _store.bulletinReviews.where((r) => r.photoId == p.id).length;
    return p.copyWith(
      author: _store.profileById(p.userId),
      likeCount: likeCount == 0 ? p.likeCount : likeCount,
      reviewCount: reviewCount,
      likedByMe: userId != null && _store.bulletinLikes.contains('${p.id}:$userId'),
    );
  }

  @override
  Future<List<BulletinPhoto>> getBulletinPhotos({String? roomId}) async {
    return _store.bulletinPhotos
        .where((p) => roomId == null || p.roomId == roomId)
        .map(_hydratePhoto)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
  }

  @override
  Future<BulletinPhoto> addBulletinPhoto({
    String? roomId,
    String? challengeId,
    required String imageUrl,
    String caption = '',
  }) async {
    final photo = BulletinPhoto(
      id: _store.newId(),
      userId: _store.currentUser!.id,
      roomId: roomId,
      challengeId: challengeId,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
      author: _store.currentUser,
    );
    _store.bulletinPhotos.add(photo);
    await _store.save();
    return _hydratePhoto(photo);
  }

  @override
  Future<void> toggleBulletinLike(String photoId) async {
    final userId = _store.currentUser!.id;
    final key = '$photoId:$userId';
    if (_store.bulletinLikes.contains(key)) {
      _store.bulletinLikes.remove(key);
    } else {
      _store.bulletinLikes.add(key);
    }
    await _store.save();
  }

  @override
  Future<List<BulletinReview>> getBulletinReviews(String photoId) async {
    return _store.bulletinReviews
        .where((r) => r.photoId == photoId)
        .map((r) => BulletinReview(
              id: r.id,
              photoId: r.photoId,
              userId: r.userId,
              body: r.body,
              createdAt: r.createdAt,
              author: _store.profileById(r.userId),
            ))
        .toList()
      ..sort((a, b) => (a.createdAt ?? DateTime.now())
          .compareTo(b.createdAt ?? DateTime.now()));
  }

  @override
  Future<BulletinReview> addBulletinReview(String photoId, String body) async {
    final review = BulletinReview(
      id: _store.newId(),
      photoId: photoId,
      userId: _store.currentUser!.id,
      body: body,
      createdAt: DateTime.now(),
      author: _store.currentUser,
    );
    _store.bulletinReviews.add(review);
    await _store.save();
    return review;
  }

  // --- Creator monetization / financial aid ---
  // Mirrors the SQL compute_monthly_payouts(): proportional fund share.

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

  Map<String, int> _likeCountsForMonth(DateTime month) {
    final start = _monthStart(month);
    final end = DateTime(start.year, start.month + 1, 1);
    final counts = <String, int>{};
    for (final post in _store.posts) {
      final n = _store.likes.where((k) => k.startsWith('${post.id}:')).length;
      // Seed posts carry a baseline likeCount with no per-user like keys.
      final seeded = n == 0 ? post.likeCount : n;
      if (seeded == 0) continue;
      // Demo likes are not timestamped per-month; attribute to current month.
      final inMonth = !start.isAfter(DateTime.now()) &&
          DateTime.now().isBefore(end);
      if (!inMonth) continue;
      counts.update(post.authorId, (v) => v + seeded, ifAbsent: () => seeded);
    }
    return counts;
  }

  @override
  Future<List<MonthlyPayout>> computeMonthlyPayouts([DateTime? month]) async {
    final m = _monthStart(month ?? DateTime.now());
    final counts = _likeCountsForMonth(m);
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    final challenge = _store.challenges
        .cast<MonthlyChallenge?>()
        .firstWhere((c) => c != null && _monthStart(c.month) == m,
            orElse: () => null);
    final pool = challenge?.prizePoolCents ?? 0;

    final results = <MonthlyPayout>[];
    counts.forEach((userId, likeCount) {
      final payoutCents =
          total > 0 ? (pool * likeCount / total).floor() : 0;
      final payout = MonthlyPayout(
        userId: userId,
        month: m,
        likeCount: likeCount,
        poolCents: pool,
        payoutCents: payoutCents,
        computedAt: DateTime.now(),
      );
      _store.payouts
          .removeWhere((p) => p.userId == userId && _monthStart(p.month) == m);
      _store.payouts.add(payout);
      results.add(payout);
    });
    await _store.save();
    return results;
  }

  @override
  Future<MonthlyPayout?> getMyPayout([DateTime? month]) async {
    final userId = _store.currentUser?.id;
    if (userId == null) return null;
    final m = _monthStart(month ?? DateTime.now());
    // Always recompute so the figure reflects the latest likes.
    final all = await computeMonthlyPayouts(m);
    return all
        .cast<MonthlyPayout?>()
        .firstWhere((p) => p!.userId == userId, orElse: () => null);
  }

  @override
  Future<String> uploadMedia({
    required String bucket,
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    // Demo mode returns a placeholder URL based on content type.
    if (contentType.startsWith('video/')) {
      return 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
    }
    return 'https://images.unsplash.com/photo-1515886657613-9f3515b0c690?w=600';
  }
}
