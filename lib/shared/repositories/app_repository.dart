import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
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
import 'demo_repository.dart';
import 'supabase_repository.dart';

abstract class AppRepository {
  Future<void> initialize();
  bool get isAuthenticated;
  Profile? get currentProfile;
  Stream<Profile?> get authStateChanges;

  Future<Profile?> signIn({required String email, required String password});
  Future<Profile?> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
  });
  Future<void> signOut();
  Future<Profile> updateProfile(Profile profile);

  Future<List<Folder>> getFolders();
  Future<Folder> createFolder({required String name, String description = ''});
  Future<void> deleteFolder(String id);
  Future<List<FolderItem>> getFolderItems(String folderId);
  Future<FolderItem> addFolderItem({
    required String folderId,
    required String imageUrl,
    String caption = '',
  });

  Future<List<Campaign>> getCampaigns();
  Future<List<Group>> getGroups();
  Future<Campaign> createCampaign({
    required String title,
    required String theme,
    String? groupId,
    bool isStarterPost = false,
  });
  Future<Group> createGroup({required String name, String description = ''});

  Future<PostDraft?> getActiveDraft();
  Future<PostDraft> saveDraftPhase1({
    required String clothesImageUrl,
    String caption = '',
    bool startNewCampaign = false,
  });
  Future<void> clearDraft();
  Future<Post> publishPost({
    required String clothesImageUrl,
    required String walkVideoUrl,
    required String title,
    String caption = '',
    bool startNewCampaign = false,
    String? campaignId,
    String? groupId,
  });

  Future<List<Post>> getFeedPosts();
  Future<Post?> getPost(String id);
  Future<List<PostComment>> getComments(String postId);
  Future<void> toggleLike(String postId);
  Future<void> toggleRepost(String postId);
  Future<PostComment> addComment(String postId, String body);

  Future<List<GiftType>> getGiftTypes();
  Future<List<Gift>> getReceivedGifts([String? userId]);
  Future<Gift> sendGift({
    required String recipientId,
    required String giftType,
    String? postId,
    String? roomId,
    String message = '',
  });

  // --- Monthly challenge engine ---
  Future<MonthlyChallenge?> getCurrentChallenge();
  Future<void> enterChallenge(String challengeId, {String? postId});

  // --- Aesthetic chat ---
  Future<List<ChatRoom>> getChatRooms();
  Future<ChatRoom?> getChatRoom(String id);
  Future<ChatRoom> getOrCreateRoom({
    required String ownerId,
    String? name,
    String? challengeId,
  });
  Future<List<ChatMessage>> getMessages(String roomId);
  Stream<List<ChatMessage>> watchMessages(String roomId);
  Future<ChatMessage> sendMessage(String roomId, String body, {String? parentId});
  Future<void> toggleMessageLike(String messageId);

  // --- Bulletin space (photo review board) ---
  Future<List<BulletinPhoto>> getBulletinPhotos({String? roomId});
  Future<BulletinPhoto> addBulletinPhoto({
    String? roomId,
    String? challengeId,
    required String imageUrl,
    String caption = '',
  });
  Future<void> toggleBulletinLike(String photoId);
  Future<List<BulletinReview>> getBulletinReviews(String photoId);
  Future<BulletinReview> addBulletinReview(String photoId, String body);

  // --- Creator monetization / financial aid ---
  Future<MonthlyPayout?> getMyPayout([DateTime? month]);
  Future<List<MonthlyPayout>> computeMonthlyPayouts([DateTime? month]);

  Future<String> uploadMedia({
    required String bucket,
    required String path,
    required List<int> bytes,
    required String contentType,
  });
}

final appRepositoryProvider = Provider<AppRepository>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) {
    return DemoRepository(ref);
  }
  return SupabaseRepository(ref);
});

final authStateProvider = StreamProvider<Profile?>((ref) async* {
  await ref.watch(demoInitializedProvider.future);
  final repo = ref.watch(appRepositoryProvider);
  yield repo.currentProfile;
  yield* repo.authStateChanges;
});

final currentProfileProvider = Provider<Profile?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(appRepositoryProvider).currentProfile;
});

final feedPostsProvider = FutureProvider<List<Post>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getFeedPosts();
});

final foldersProvider = FutureProvider<List<Folder>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getFolders();
});

final campaignsProvider = FutureProvider<List<Campaign>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getCampaigns();
});

final groupsProvider = FutureProvider<List<Group>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getGroups();
});

final giftTypesProvider = FutureProvider<List<GiftType>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getGiftTypes();
});

final receivedGiftsProvider = FutureProvider<List<Gift>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getReceivedGifts();
});

final postDraftProvider = FutureProvider<PostDraft?>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getActiveDraft();
});

final currentChallengeProvider = FutureProvider<MonthlyChallenge?>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getCurrentChallenge();
});

final chatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getChatRooms();
});

final chatRoomProvider =
    FutureProvider.family<ChatRoom?, String>((ref, id) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getChatRoom(id);
});

/// Realtime message stream for a room (Supabase realtime; local broadcast in demo).
final roomMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) async* {
  await ref.watch(demoInitializedProvider.future);
  yield* ref.watch(appRepositoryProvider).watchMessages(roomId);
});

final bulletinPhotosProvider =
    FutureProvider.family<List<BulletinPhoto>, String?>((ref, roomId) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getBulletinPhotos(roomId: roomId);
});

final bulletinReviewsProvider =
    FutureProvider.family<List<BulletinReview>, String>((ref, photoId) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getBulletinReviews(photoId);
});

final myPayoutProvider = FutureProvider<MonthlyPayout?>((ref) async {
  await ref.watch(demoInitializedProvider.future);
  return ref.watch(appRepositoryProvider).getMyPayout();
});
