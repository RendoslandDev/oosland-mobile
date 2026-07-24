import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import '../../core/supabase/supabase_client.dart';
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

class SupabaseRepository implements AppRepository {
  SupabaseRepository(this.ref);

  final Ref ref;
  final _authController = StreamController<Profile?>.broadcast();
  Profile? _cachedProfile;
  final _profileCache = <String, Profile>{};

  SupabaseClient get _client => ref.read(supabaseClientProvider)!;

  @override
  Future<void> initialize() async {
    final session = _client.auth.currentSession;
    if (session != null) {
      _cachedProfile = await _fetchProfile(session.user.id);
    }
    _authController.add(_cachedProfile);
    _client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        _cachedProfile = await _fetchProfile(data.session!.user.id);
      } else {
        _cachedProfile = null;
      }
      _authController.add(_cachedProfile);
    });
  }

  Future<Profile?> _fetchProfile(String id) async {
    final data =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  @override
  bool get isAuthenticated => _client.auth.currentSession != null;

  @override
  Profile? get currentProfile => _cachedProfile;

  @override
  Stream<Profile?> get authStateChanges => _authController.stream;

  @override
  Future<Profile?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    _cachedProfile = await _fetchProfile(response.user!.id);
    return _cachedProfile;
  }

  @override
  Future<Profile?> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
        'username': username,
      },
    );
    if (response.user == null) return null;
    _cachedProfile = await _fetchProfile(response.user!.id);
    return _cachedProfile;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
    _cachedProfile = null;
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    final data = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
    _cachedProfile = Profile.fromJson(data);
    return _cachedProfile!;
  }

  @override
  Future<List<Folder>> getFolders() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('folders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Folder.fromJson(e)).toList();
  }

  @override
  Future<Folder> createFolder({
    required String name,
    String description = '',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('folders')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
        })
        .select()
        .single();
    return Folder.fromJson(data);
  }

  @override
  Future<void> deleteFolder(String id) async {
    await _client.from('folders').delete().eq('id', id);
  }

  @override
  Future<List<FolderItem>> getFolderItems(String folderId) async {
    final data = await _client
        .from('folder_items')
        .select()
        .eq('folder_id', folderId)
        .order('sort_order');
    return (data as List).map((e) => FolderItem.fromJson(e)).toList();
  }

  @override
  Future<FolderItem> addFolderItem({
    required String folderId,
    required String imageUrl,
    String caption = '',
  }) async {
    final data = await _client
        .from('folder_items')
        .insert({
          'folder_id': folderId,
          'image_url': imageUrl,
          'caption': caption,
        })
        .select()
        .single();
    return FolderItem.fromJson(data);
  }

  @override
  Future<List<Campaign>> getCampaigns() async {
    final data = await _client
        .from('campaigns')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => Campaign.fromJson(e)).toList();
  }

  @override
  Future<List<Group>> getGroups() async {
    final data = await _client.from('groups').select();
    return (data as List).map((e) => Group.fromJson(e)).toList();
  }

  @override
  Future<Campaign> createCampaign({
    required String title,
    required String theme,
    String? groupId,
    bool isStarterPost = false,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('campaigns')
        .insert({
          'creator_id': userId,
          'title': title,
          'theme': theme,
          'group_id': groupId,
          'is_starter_post': isStarterPost,
          'status': 'active',
          'starts_at': DateTime.now().toIso8601String(),
          'ends_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        })
        .select()
        .single();
    return Campaign.fromJson(data);
  }

  @override
  Future<Group> createGroup({
    required String name,
    String description = '',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('groups')
        .insert({
          'owner_id': userId,
          'name': name,
          'description': description,
        })
        .select()
        .single();
    await _client.from('group_members').insert({
      'group_id': data['id'],
      'user_id': userId,
      'role': 'owner',
    });
    return Group.fromJson(data);
  }

  @override
  Future<PostDraft?> getActiveDraft() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('post_drafts')
        .select()
        .eq('author_id', userId)
        .order('updated_at', ascending: false)
        .maybeSingle();
    if (data == null) return null;
    return PostDraft.fromJson(data);
  }

  @override
  Future<PostDraft> saveDraftPhase1({
    required String clothesImageUrl,
    String caption = '',
    bool startNewCampaign = false,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await getActiveDraft();
    if (existing != null) {
      final data = await _client
          .from('post_drafts')
          .update({
            'clothes_image_url': clothesImageUrl,
            'caption': caption,
            'start_new_campaign': startNewCampaign,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing.id)
          .select()
          .single();
      return PostDraft.fromJson(data);
    }
    final data = await _client
        .from('post_drafts')
        .insert({
          'author_id': userId,
          'clothes_image_url': clothesImageUrl,
          'caption': caption,
          'start_new_campaign': startNewCampaign,
        })
        .select()
        .single();
    return PostDraft.fromJson(data);
  }

  @override
  Future<void> clearDraft() async {
    final draft = await getActiveDraft();
    if (draft != null) {
      await _client.from('post_drafts').delete().eq('id', draft.id);
    }
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
    final userId = _client.auth.currentUser!.id;
    String? resolvedCampaignId = campaignId;
    String? resolvedGroupId = groupId;

    if (startNewCampaign) {
      final group = await createGroup(name: title, description: caption);
      resolvedGroupId = group.id;
      final campaign = await createCampaign(
        title: title,
        theme: title,
        groupId: group.id,
        isStarterPost: true,
      );
      resolvedCampaignId = campaign.id;
    }

    final data = await _client
        .from('posts')
        .insert({
          'author_id': userId,
          'title': title,
          'caption': caption,
          'clothes_image_url': clothesImageUrl,
          'walk_video_url': walkVideoUrl,
          'campaign_id': resolvedCampaignId,
          'group_id': resolvedGroupId,
          'is_starter_post': startNewCampaign,
        })
        .select('*, profiles(*)')
        .single();

    await clearDraft();
    return Post.fromJson(data);
  }

  Future<Post> _hydratePost(Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser?.id;
    final postId = data['id'] as String;
    final likes = await _client
        .from('post_likes')
        .select('user_id')
        .eq('post_id', postId);
    final reposts = await _client
        .from('post_reposts')
        .select('user_id')
        .eq('post_id', postId);
    final comments = await _client
        .from('post_comments')
        .select('id')
        .eq('post_id', postId);

    data['like_count'] = (likes as List).length;
    data['repost_count'] = (reposts as List).length;
    data['comment_count'] = (comments as List).length;
    if (userId != null) {
      data['liked_by_me'] =
          (likes).any((l) => l['user_id'] == userId);
      data['reposted_by_me'] =
          (reposts).any((r) => r['user_id'] == userId);
    }
    return Post.fromJson(data);
  }

  @override
  Future<List<Post>> getFeedPosts() async {
    final data = await _client
        .from('posts')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    final posts = <Post>[];
    for (final row in data as List) {
      posts.add(await _hydratePost(row));
    }
    return posts;
  }

  @override
  Future<Post?> getPost(String id) async {
    final data = await _client
        .from('posts')
        .select('*, profiles(*)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return _hydratePost(data);
  }

  @override
  Future<List<PostComment>> getComments(String postId) async {
    final data = await _client
        .from('post_comments')
        .select('*, profiles(*)')
        .eq('post_id', postId)
        .order('created_at');
    return (data as List).map((e) => PostComment.fromJson(e)).toList();
  }

  @override
  Future<void> toggleLike(String postId) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from('post_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  @override
  Future<void> toggleRepost(String postId) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from('post_reposts')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('post_reposts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _client.from('post_reposts').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  @override
  Future<PostComment> addComment(String postId, String body) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('post_comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'body': body,
        })
        .select('*, profiles(*)')
        .single();
    return PostComment.fromJson(data);
  }

  @override
  Future<List<GiftType>> getGiftTypes() async {
    final data = await _client.from('gift_types').select();
    return (data as List).map((e) => GiftType.fromJson(e)).toList();
  }

  @override
  Future<List<Gift>> getReceivedGifts([String? userId]) async {
    final id = userId ?? _client.auth.currentUser!.id;
    final data = await _client
        .from('gifts')
        .select('*, gift_types(*), sender:profiles!gifts_sender_id_fkey(*)')
        .eq('recipient_id', id)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Gift.fromJson(e)).toList();
  }

  @override
  Future<Gift> sendGift({
    required String recipientId,
    required String giftType,
    String? postId,
    String? roomId,
    String message = '',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('gifts')
        .insert({
          'sender_id': userId,
          'recipient_id': recipientId,
          'gift_type': giftType,
          'post_id': postId,
          'room_id': roomId,
          'message': message,
        })
        .select('*, gift_types(*)')
        .single();
    return Gift.fromJson(data);
  }

  // --- Monthly challenge engine ---

  @override
  Future<MonthlyChallenge?> getCurrentChallenge() async {
    final nowIso = DateTime.now().toIso8601String();
    final data = await _client
        .from('monthly_challenges')
        .select()
        .lte('starts_at', nowIso)
        .gte('ends_at', nowIso)
        .order('starts_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (data == null) return null;
    final challenge = MonthlyChallenge.fromJson(data);

    final userId = _client.auth.currentUser?.id;
    final entries = await _client
        .from('challenge_entries')
        .select('user_id')
        .eq('challenge_id', challenge.id);
    final list = entries as List;
    return challenge.copyWith(
      entryCount: list.length,
      enteredByMe: userId != null && list.any((e) => e['user_id'] == userId),
    );
  }

  @override
  Future<void> enterChallenge(String challengeId, {String? postId}) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('challenge_entries').insert({
      'challenge_id': challengeId,
      'user_id': userId,
      'post_id': postId,
    });
  }

  // --- Aesthetic chat ---

  @override
  Future<List<ChatRoom>> getChatRooms() async {
    final data = await _client
        .from('chat_rooms')
        .select('*, profiles(*)')
        .order('created_at', ascending: false);
    return (data as List).map((e) => ChatRoom.fromJson(e)).toList();
  }

  @override
  Future<ChatRoom?> getChatRoom(String id) async {
    final data = await _client
        .from('chat_rooms')
        .select('*, profiles(*)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return ChatRoom.fromJson(data);
  }

  @override
  Future<ChatRoom> getOrCreateRoom({
    required String ownerId,
    String? name,
    String? challengeId,
  }) async {
    final existing = await _client
        .from('chat_rooms')
        .select('*, profiles(*)')
        .eq('owner_id', ownerId)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    if (existing != null) return ChatRoom.fromJson(existing);

    final data = await _client
        .from('chat_rooms')
        .insert({
          'owner_id': ownerId,
          'name': name ?? 'Creator Lounge',
          'challenge_id': challengeId,
        })
        .select('*, profiles(*)')
        .single();
    return ChatRoom.fromJson(data);
  }

  Future<void> _ensureProfiles(Set<String> ids) async {
    final missing = ids.where((id) => !_profileCache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    final data =
        await _client.from('profiles').select().inFilter('id', missing);
    for (final row in data as List) {
      final p = Profile.fromJson(row);
      _profileCache[p.id] = p;
    }
  }

  Future<List<ChatMessage>> _hydrateMessages(List rows) async {
    if (rows.isEmpty) return [];
    final userId = _client.auth.currentUser?.id;
    final ids = rows.map((r) => r['id'] as String).toList();
    final stats = await _client
        .from('chat_message_stats')
        .select()
        .inFilter('message_id', ids);
    final statMap = {
      for (final s in stats as List) s['message_id']: s,
    };
    final likedSet = <String>{};
    if (userId != null) {
      final myLikes = await _client
          .from('chat_message_likes')
          .select('message_id')
          .eq('user_id', userId)
          .inFilter('message_id', ids);
      for (final l in myLikes as List) {
        likedSet.add(l['message_id'] as String);
      }
    }
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      final s = statMap[m['id']];
      m['like_count'] = s?['like_count'] ?? 0;
      m['reply_count'] = s?['reply_count'] ?? 0;
      m['liked_by_me'] = likedSet.contains(m['id']);
      return ChatMessage.fromJson(m);
    }).toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String roomId) async {
    final data = await _client
        .from('chat_messages')
        .select('*, profiles(*)')
        .eq('room_id', roomId)
        .isFilter('parent_id', null)
        .order('created_at');
    return _hydrateMessages(data as List);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String roomId) {
    // Realtime stream of top-level messages. Like/reply counts are not part of
    // the realtime payload, so they default to 0 here and are reconciled by the
    // UI (optimistic like state + a getMessages refresh on demand).
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .asyncMap((rows) async {
      final top = rows.where((r) => r['parent_id'] == null).toList();
      await _ensureProfiles(top.map((r) => r['user_id'] as String).toSet());
      return top.map((r) {
        final m = Map<String, dynamic>.from(r);
        final prof = _profileCache[m['user_id']];
        if (prof != null) m['profiles'] = prof.toJson();
        return ChatMessage.fromJson(m);
      }).toList();
    });
  }

  @override
  Future<ChatMessage> sendMessage(String roomId, String body,
      {String? parentId}) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('chat_messages')
        .insert({
          'room_id': roomId,
          'user_id': userId,
          'body': body,
          'parent_id': parentId,
        })
        .select('*, profiles(*)')
        .single();
    return ChatMessage.fromJson(data);
  }

  @override
  Future<void> toggleMessageLike(String messageId) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from('chat_message_likes')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('chat_message_likes')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);
    } else {
      await _client.from('chat_message_likes').insert({
        'message_id': messageId,
        'user_id': userId,
      });
    }
  }

  // --- Bulletin space ---

  Future<List<BulletinPhoto>> _hydratePhotos(List rows) async {
    if (rows.isEmpty) return [];
    final userId = _client.auth.currentUser?.id;
    final ids = rows.map((r) => r['id'] as String).toList();
    final stats = await _client
        .from('bulletin_photo_stats')
        .select()
        .inFilter('photo_id', ids);
    final statMap = {for (final s in stats as List) s['photo_id']: s};
    final likedSet = <String>{};
    if (userId != null) {
      final myLikes = await _client
          .from('bulletin_photo_likes')
          .select('photo_id')
          .eq('user_id', userId)
          .inFilter('photo_id', ids);
      for (final l in myLikes as List) {
        likedSet.add(l['photo_id'] as String);
      }
    }
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      final s = statMap[m['id']];
      m['like_count'] = s?['like_count'] ?? 0;
      m['review_count'] = s?['review_count'] ?? 0;
      m['liked_by_me'] = likedSet.contains(m['id']);
      return BulletinPhoto.fromJson(m);
    }).toList();
  }

  @override
  Future<List<BulletinPhoto>> getBulletinPhotos({String? roomId}) async {
    var query = _client.from('bulletin_photos').select('*, profiles(*)');
    if (roomId != null) query = query.eq('room_id', roomId);
    final data = await query.order('created_at', ascending: false);
    return _hydratePhotos(data as List);
  }

  @override
  Future<BulletinPhoto> addBulletinPhoto({
    String? roomId,
    String? challengeId,
    required String imageUrl,
    String caption = '',
  }) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('bulletin_photos')
        .insert({
          'user_id': userId,
          'room_id': roomId,
          'challenge_id': challengeId,
          'image_url': imageUrl,
          'caption': caption,
        })
        .select('*, profiles(*)')
        .single();
    return BulletinPhoto.fromJson(data);
  }

  @override
  Future<void> toggleBulletinLike(String photoId) async {
    final userId = _client.auth.currentUser!.id;
    final existing = await _client
        .from('bulletin_photo_likes')
        .select()
        .eq('photo_id', photoId)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('bulletin_photo_likes')
          .delete()
          .eq('photo_id', photoId)
          .eq('user_id', userId);
    } else {
      await _client.from('bulletin_photo_likes').insert({
        'photo_id': photoId,
        'user_id': userId,
      });
    }
  }

  @override
  Future<List<BulletinReview>> getBulletinReviews(String photoId) async {
    final data = await _client
        .from('bulletin_reviews')
        .select('*, profiles(*)')
        .eq('photo_id', photoId)
        .order('created_at');
    return (data as List).map((e) => BulletinReview.fromJson(e)).toList();
  }

  @override
  Future<BulletinReview> addBulletinReview(String photoId, String body) async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('bulletin_reviews')
        .insert({
          'photo_id': photoId,
          'user_id': userId,
          'body': body,
        })
        .select('*, profiles(*)')
        .single();
    return BulletinReview.fromJson(data);
  }

  // --- Creator monetization / financial aid ---

  String _monthParam(DateTime? month) {
    final d = month ?? DateTime.now();
    final m = DateTime(d.year, d.month, 1);
    return '${m.year.toString().padLeft(4, '0')}-'
        '${m.month.toString().padLeft(2, '0')}-01';
  }

  @override
  Future<List<MonthlyPayout>> computeMonthlyPayouts([DateTime? month]) async {
    final data = await _client.rpc(
      'compute_monthly_payouts',
      params: {'p_month': _monthParam(month)},
    );
    return (data as List).map((e) => MonthlyPayout.fromJson(e)).toList();
  }

  @override
  Future<MonthlyPayout?> getMyPayout([DateTime? month]) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final all = await computeMonthlyPayouts(month);
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
    await _client.storage.from(bucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
