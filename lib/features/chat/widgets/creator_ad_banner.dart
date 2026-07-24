import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/repositories/app_repository.dart';

/// TikTok-style commercial ad banner. Shows a creator's avatar + tagline and a
/// one-click CTA that instantly funnels the viewer into the creator's chat room.
class CreatorAdBanner extends ConsumerStatefulWidget {
  const CreatorAdBanner({
    super.key,
    required this.creator,
    this.tagline = 'Join the live community',
    this.ctaLabel = 'Enter Chat',
  });

  final Profile creator;
  final String tagline;
  final String ctaLabel;

  @override
  ConsumerState<CreatorAdBanner> createState() => _CreatorAdBannerState();
}

class _CreatorAdBannerState extends ConsumerState<CreatorAdBanner> {
  bool _loading = false;

  Future<void> _enter() async {
    setState(() => _loading = true);
    try {
      final challenge = await ref.read(currentChallengeProvider.future);
      final room = await ref.read(appRepositoryProvider).getOrCreateRoom(
            ownerId: widget.creator.id,
            name: '${widget.creator.displayName} Lounge',
            challengeId: challenge?.id,
          );
      if (mounted) context.push('/chat/${room.id}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creator = widget.creator;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, Color(0xFFB5123A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                backgroundImage: creator.avatarUrl != null
                    ? NetworkImage(creator.avatarUrl!)
                    : null,
                child: creator.avatarUrl == null
                    ? Text(
                        creator.displayName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _loading ? null : _enter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text(
                      widget.ctaLabel,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
