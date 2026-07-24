import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bulletin.dart';
import '../../../shared/repositories/app_repository.dart';

/// Interactive photo review board embedded in a chat room. Followers upload
/// photos, like individual entries, and leave text reviews.
class BulletinSpace extends ConsumerWidget {
  const BulletinSpace({super.key, this.roomId, this.challengeId});

  final String? roomId;
  final String? challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(bulletinPhotosProvider(roomId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              const Text(
                'Bulletin Space',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _addPhoto(context, ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 15, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Post photo',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        photosAsync.when(
          data: (photos) {
            if (photos.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.tile),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        color: AppColors.textSecondary),
                    SizedBox(height: 6),
                    Text(
                      'No photos yet — be the first to post a look.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _PhotoCard(
                  photo: photos[i],
                  roomId: roomId,
                ),
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          ),
          error: (e, _) => Text('Could not load bulletin: $e'),
        ),
      ],
    );
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final repo = ref.read(appRepositoryProvider);
    final userId = ref.read(currentProfileProvider)?.id ?? 'demo';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final url = await repo.uploadMedia(
      bucket: 'bulletin',
      path: path,
      bytes: bytes,
      contentType: 'image/jpeg',
    );
    await repo.addBulletinPhoto(
      roomId: roomId,
      challengeId: challengeId,
      imageUrl: url,
    );
    ref.invalidate(bulletinPhotosProvider(roomId));
  }
}

class _PhotoCard extends ConsumerWidget {
  const _PhotoCard({required this.photo, required this.roomId});

  final BulletinPhoto photo;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showReviews(context, ref),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      photo.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.selectedNav,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: _LikeChip(photo: photo, roomId: roomId),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              photo.caption.isEmpty ? 'Untitled look' : photo.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              '${photo.reviewCount} reviews',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviews(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final reviewsAsync =
                  ref.watch(bulletinReviewsProvider(photo.id));
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Reviews',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      _LikeChip(photo: photo, roomId: roomId),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: reviewsAsync.when(
                      data: (reviews) => reviews.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No reviews yet — leave the first.',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: reviews
                                  .map((r) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              AppColors.selectedNav,
                                          child: Text(
                                            (r.author?.displayName ?? '?')
                                                .characters
                                                .first
                                                .toUpperCase(),
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        title: Text(
                                            r.author?.displayName ?? 'User',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                        subtitle: Text(r.body),
                                      ))
                                  .toList(),
                            ),
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent)),
                      error: (e, _) => Text('$e'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                              hintText: 'Write a review...'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () async {
                          final body = controller.text.trim();
                          if (body.isEmpty) return;
                          await ref
                              .read(appRepositoryProvider)
                              .addBulletinReview(photo.id, body);
                          controller.clear();
                          ref.invalidate(bulletinReviewsProvider(photo.id));
                          ref.invalidate(bulletinPhotosProvider(roomId));
                        },
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _LikeChip extends ConsumerWidget {
  const _LikeChip({required this.photo, required this.roomId});

  final BulletinPhoto photo;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await ref.read(appRepositoryProvider).toggleBulletinLike(photo.id);
        ref.invalidate(bulletinPhotosProvider(roomId));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              photo.likedByMe ? Icons.favorite : Icons.favorite_border,
              size: 13,
              color: photo.likedByMe ? AppColors.accent : AppColors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${photo.likeCount}',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
