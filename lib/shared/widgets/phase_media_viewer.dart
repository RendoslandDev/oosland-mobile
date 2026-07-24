import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../models/post.dart';

class CampaignBadge extends StatelessWidget {
  const CampaignBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: const Text(
        '★  This started a campaign',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class PhaseMediaViewer extends StatefulWidget {
  const PhaseMediaViewer({
    super.key,
    required this.post,
    this.initialPhase = 1,
    this.autoPlayVideo = false,
  });

  final Post post;
  final int initialPhase;
  final bool autoPlayVideo;

  @override
  State<PhaseMediaViewer> createState() => _PhaseMediaViewerState();
}

class _PhaseMediaViewerState extends State<PhaseMediaViewer> {
  late int _phase;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase;
    if (_phase == 1 && widget.autoPlayVideo) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant PhaseMediaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_phase == 1 && widget.autoPlayVideo && _videoController == null) {
      _initVideo();
    }
    if (_phase == 0) {
      _videoController?.pause();
    }
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.walkVideoUrl),
    );
    await controller.initialize();
    controller.setLooping(true);
    if (widget.autoPlayVideo) {
      await controller.play();
    }
    if (mounted) {
      setState(() => _videoController = controller);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _setPhase(int phase) {
    setState(() => _phase = phase);
    if (phase == 1) {
      _initVideo();
    } else {
      _videoController?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PhasePill(
              label: 'Phase 1',
              subtitle: 'Clothes',
              selected: _phase == 0,
              onTap: () => _setPhase(0),
            ),
            const SizedBox(width: 8),
            _PhasePill(
              label: 'Phase 2',
              subtitle: 'Walk',
              selected: _phase == 1,
              onTap: () => _setPhase(1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _phase == 0 ? _buildClothes() : _buildVideo(),
          ),
        ),
      ],
    );
  }

  Widget _buildClothes() {
    return CachedNetworkImage(
      imageUrl: widget.post.clothesImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(color: AppColors.selectedNav),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.selectedNav,
        child: const Icon(Icons.checkroom_outlined, size: 48),
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: AppColors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.white),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: IconButton(
            onPressed: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
              setState(() {});
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
