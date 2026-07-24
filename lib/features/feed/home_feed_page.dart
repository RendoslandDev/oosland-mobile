import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/post.dart';
import '../../shared/repositories/app_repository.dart';
import '../../shared/widgets/phase_media_viewer.dart';
import '../chat/widgets/challenge_banner.dart';
import '../chat/widgets/creator_ad_banner.dart';

class HomeFeedPage extends ConsumerWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedPostsProvider);
    final challenge = ref.watch(currentChallengeProvider).valueOrNull;

    return feedAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyState(
            title: 'No looks yet',
            subtitle: 'Create a campaign submission with clothes photo + walk video.',
            icon: Icons.grid_view_rounded,
          );
        }
        // Feature a creator for the ad banner: prefer a starter-post author.
        final featured = posts
            .firstWhere((p) => p.isStarterPost && p.author != null,
                orElse: () => posts.first)
            .author;
        final header = Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              if (challenge != null) ...[
                ChallengeBanner(challenge: challenge),
                const SizedBox(height: 12),
              ],
              if (featured != null) CreatorAdBanner(creator: featured),
            ],
          ),
        );
        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(feedPostsProvider);
            ref.invalidate(currentChallengeProvider);
            await ref.read(feedPostsProvider.future);
          },
          child: _MasonryGrid(
            posts: posts,
            header: header,
            onTap: (post) => context.push('/post/${post.id}'),
            onLike: (post) async {
              await ref.read(appRepositoryProvider).toggleLike(post.id);
              ref.invalidate(feedPostsProvider);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => EmptyState(title: 'Could not load feed', subtitle: '$e'),
    );
  }
}

/// Pinterest-style two-column staggered grid. Dependency-free: items are
/// dealt into the shorter column so heights stay balanced, and each tile's
/// height is derived deterministically from its id for the masonry look.
class _MasonryGrid extends StatelessWidget {
  const _MasonryGrid({
    required this.posts,
    required this.onTap,
    required this.onLike,
    this.header,
  });

  final List<Post> posts;
  final void Function(Post) onTap;
  final void Function(Post) onLike;
  final Widget? header;

  // Repeating set of cover ratios → staggered heights.
  static const _ratios = [1.15, 1.45, 0.95, 1.3, 1.05, 1.55];

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    var leftWeight = 0.0;
    var rightWeight = 0.0;

    for (var i = 0; i < posts.length; i++) {
      final post = posts[i];
      final ratio = _ratios[i % _ratios.length];
      final tile = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _LookTile(
          post: post,
          heightRatio: ratio,
          onTap: () => onTap(post),
          onLike: () => onLike(post),
        ),
      );
      if (leftWeight <= rightWeight) {
        left.add(tile);
        leftWeight += ratio;
      } else {
        right.add(tile);
        rightWeight += ratio;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
      children: [
        ?header,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            const SizedBox(width: 12),
            Expanded(child: Column(children: right)),
          ],
        ),
      ],
    );
  }
}

class _LookTile extends StatelessWidget {
  const _LookTile({
    required this.post,
    required this.heightRatio,
    required this.onTap,
    required this.onLike,
  });

  final Post post;
  final double heightRatio;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1 / heightRatio,
                  child: Image.network(
                    post.clothesImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.selectedNav,
                      child: const Icon(Icons.checkroom_outlined, size: 40),
                    ),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                            ? child
                            : Container(color: AppColors.selectedNav),
                  ),
                ),
                if (post.isStarterPost)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _CampaignTag(),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _LikePill(
                    liked: post.likedByMe,
                    count: post.likeCount,
                    onTap: onLike,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.25,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.selectedNav,
                backgroundImage: post.author?.avatarUrl != null
                    ? NetworkImage(post.author!.avatarUrl!)
                    : null,
                child: post.author?.avatarUrl == null
                    ? Text(
                        (post.author?.displayName ?? '?')
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.author?.displayName ?? 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _LikePill extends StatelessWidget {
  const _LikePill({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: liked ? AppColors.accent : AppColors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
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

class _CampaignTag extends StatelessWidget {
  const _CampaignTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Text(
        '★ Campaign',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final postProvider = FutureProvider.family<Post?, String>((ref, id) async {
  return ref.read(appRepositoryProvider).getPost(id);
});

final postCommentsProvider =
    FutureProvider.family<List<PostComment>, String>((ref, postId) async {
  return ref.read(appRepositoryProvider).getComments(postId);
});

class PostDetailPage extends ConsumerStatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    return postAsync.when(
      data: (post) {
        if (post == null) {
          return const Scaffold(
            body: EmptyState(title: 'Post not found'),
          );
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: CircleAvatar(
                radius: 16,
                backgroundImage: post.author?.avatarUrl != null
                    ? NetworkImage(post.author!.avatarUrl!)
                    : null,
                child: post.author?.avatarUrl == null
                    ? Text(
                        (post.author?.displayName ?? '?')
                            .characters
                            .first
                            .toUpperCase(),
                      )
                    : null,
              ),
            ),
            title: Text(
              post.title.isEmpty ? 'Post' : post.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            actions: [
              TextButton(
                onPressed: () => _showGiftPicker(context, post),
                child: const Text(
                  'Gift',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (post.isStarterPost) ...[
                const CampaignBadge(),
                const SizedBox(height: 16),
              ],
              PhaseMediaViewer(post: post, autoPlayVideo: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      await ref
                          .read(appRepositoryProvider)
                          .toggleLike(post.id);
                      ref.invalidate(postProvider(widget.postId));
                      ref.invalidate(feedPostsProvider);
                    },
                    icon: Icon(
                      post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    ),
                  ),
                  Text('${post.likeCount}'),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () async {
                      await ref
                          .read(appRepositoryProvider)
                          .toggleRepost(post.id);
                      ref.invalidate(postProvider(widget.postId));
                    },
                    icon: const Icon(Icons.repeat),
                  ),
                  Text('${post.repostCount}'),
                ],
              ),
              if (post.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(post.caption),
                ),
              const Text(
                'Text and reply',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a reply...',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final body = _commentController.text.trim();
                      if (body.isEmpty) return;
                      await ref
                          .read(appRepositoryProvider)
                          .addComment(post.id, body);
                      _commentController.clear();
                      ref.invalidate(postCommentsProvider(widget.postId));
                      ref.invalidate(postProvider(widget.postId));
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              commentsAsync.when(
                data: (comments) => Column(
                  children: comments
                      .map(
                        (c) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              (c.author?.displayName ?? '?')
                                  .characters
                                  .first
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(c.author?.displayName ?? 'User'),
                          subtitle: Text(c.body),
                        ),
                      )
                      .toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: EmptyState(title: 'Error', subtitle: '$e')),
    );
  }

  Future<void> _showGiftPicker(BuildContext context, post) async {
    final giftTypes = await ref.read(giftTypesProvider.future);
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Send a gift',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...giftTypes.map(
                (type) => ListTile(
                  leading: Text(type.icon, style: const TextStyle(fontSize: 28)),
                  title: Text(type.name),
                  onTap: () async {
                    await ref.read(appRepositoryProvider).sendGift(
                          recipientId: post.authorId,
                          giftType: type.id,
                          postId: post.id,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${type.name} sent!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
