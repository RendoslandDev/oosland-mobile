import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/post.dart';
import '../../../shared/repositories/app_repository.dart';
import '../../../shared/widgets/phase_media_viewer.dart';

class UploadWizardPage extends ConsumerStatefulWidget {
  const UploadWizardPage({super.key});

  @override
  ConsumerState<UploadWizardPage> createState() => _UploadWizardPageState();
}

class _UploadWizardPageState extends ConsumerState<UploadWizardPage> {
  int _step = 0;
  Uint8List? _clothesBytes;
  String? _clothesUrl;
  Uint8List? _videoBytes;
  String? _videoUrl;
  final _captionController = TextEditingController();
  final _titleController = TextEditingController();
  bool _startNewCampaign = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(postDraftProvider.future);
    if (draft != null && mounted) {
      setState(() {
        _clothesUrl = draft.clothesImageUrl;
        _captionController.text = draft.caption;
        _startNewCampaign = draft.startNewCampaign;
        _step = 1;
      });
    }
  }

  Future<void> _pickClothes() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _clothesBytes = bytes);
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _videoBytes = bytes);
  }

  Future<void> _savePhase1() async {
    if (_clothesBytes == null && _clothesUrl == null) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      final userId = ref.read(currentProfileProvider)?.id ?? 'demo';
      final url = _clothesUrl ??
          await repo.uploadMedia(
            bucket: 'posts',
            path: '$userId/clothes_${DateTime.now().millisecondsSinceEpoch}.jpg',
            bytes: _clothesBytes!,
            contentType: 'image/jpeg',
          );
      await repo.saveDraftPhase1(
        clothesImageUrl: url,
        caption: _captionController.text.trim(),
        startNewCampaign: _startNewCampaign,
      );
      setState(() {
        _clothesUrl = url;
        _step = 1;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    if ((_clothesBytes == null && _clothesUrl == null) ||
        (_videoBytes == null && _videoUrl == null)) {
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(appRepositoryProvider);
      final userId = ref.read(currentProfileProvider)?.id ?? 'demo';
      final clothesUrl = _clothesUrl ??
          await repo.uploadMedia(
            bucket: 'posts',
            path: '$userId/clothes_${DateTime.now().millisecondsSinceEpoch}.jpg',
            bytes: _clothesBytes!,
            contentType: 'image/jpeg',
          );
      final videoUrl = _videoUrl ??
          await repo.uploadMedia(
            bucket: 'posts',
            path: '$userId/walk_${DateTime.now().millisecondsSinceEpoch}.mp4',
            bytes: _videoBytes!,
            contentType: 'video/mp4',
          );

      await repo.publishPost(
        clothesImageUrl: clothesUrl,
        walkVideoUrl: videoUrl,
        title: _titleController.text.trim().isEmpty
            ? 'Untitled look'
            : _titleController.text.trim(),
        caption: _captionController.text.trim(),
        startNewCampaign: _startNewCampaign,
      );

      ref.invalidate(feedPostsProvider);
      ref.invalidate(campaignsProvider);
      ref.invalidate(groupsProvider);
      ref.invalidate(postDraftProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign post published!')),
        );
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Upload',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? 'Phase 1 — Photo of the dress or clothes'
                  : _step == 1
                      ? 'Phase 2 — Video walking in the outfit'
                      : 'Review both phases before publishing',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _StepIndicator(current: _step),
            const SizedBox(height: 24),
            if (_step == 0) ...[
              _MediaPickerBox(
                label: 'Clothes photo',
                hint: 'Flat lay, hanger, or product shot',
                bytes: _clothesBytes,
                url: _clothesUrl,
                onPick: _pickClothes,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start a new campaign'),
                value: _startNewCampaign,
                onChanged: (v) => setState(() => _startNewCampaign = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_clothesBytes != null || _clothesUrl != null) &&
                        !_loading
                    ? _savePhase1
                    : null,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Next: record your walk'),
              ),
            ] else if (_step == 1) ...[
              _MediaPickerBox(
                label: 'Walk video',
                hint: 'Vertical video of you in the outfit',
                bytes: _videoBytes,
                url: _videoUrl,
                isVideo: true,
                onPick: _pickVideo,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Post title'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step = 0),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_videoBytes != null || _videoUrl != null) &&
                              !_loading
                          ? () => setState(() => _step = 2)
                          : null,
                      child: const Text('Review'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (_clothesUrl != null && (_videoUrl != null || _videoBytes != null))
                PhaseMediaViewer(
                  post: _previewPost(),
                  autoPlayVideo: false,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step = 1),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_loading ? _publish : null,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Upload'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Post _previewPost() {
    return Post(
      id: 'preview',
      authorId: ref.read(currentProfileProvider)?.id ?? '',
      clothesImageUrl: _clothesUrl!,
      walkVideoUrl: _videoUrl ??
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
      title: _titleController.text,
      caption: _captionController.text,
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot('1', 'Clothes', current >= 0),
        Expanded(child: Container(height: 1, color: AppColors.border)),
        _dot('2', 'Walk', current >= 1),
        Expanded(child: Container(height: 1, color: AppColors.border)),
        _dot('3', 'Publish', current >= 2),
      ],
    );
  }

  Widget _dot(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active ? AppColors.black : AppColors.border,
          child: Text(
            number,
            style: TextStyle(
              color: active ? AppColors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _MediaPickerBox extends StatelessWidget {
  const _MediaPickerBox({
    required this.label,
    required this.hint,
    required this.onPick,
    this.bytes,
    this.url,
    this.isVideo = false,
  });

  final String label;
  final String hint;
  final VoidCallback onPick;
  final Uint8List? bytes;
  final String? url;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final hasMedia = bytes != null || url != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          image: bytes != null && !isVideo
              ? DecorationImage(
                  image: MemoryImage(bytes!),
                  fit: BoxFit.cover,
                )
              : url != null && !isVideo
                  ? DecorationImage(
                      image: NetworkImage(url!),
                      fit: BoxFit.cover,
                    )
                  : null,
        ),
        child: hasMedia && isVideo
            ? const Center(
                child: Icon(Icons.videocam, size: 48),
              )
            : hasMedia
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(hint, style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
      ),
    );
  }
}
