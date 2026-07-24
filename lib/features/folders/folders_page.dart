import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/folder.dart';
import '../../shared/repositories/app_repository.dart';
import '../../shared/widgets/phase_media_viewer.dart';

class FoldersPage extends ConsumerWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      data: (folders) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Boards',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _createFolder(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 18, color: AppColors.white),
                            SizedBox(width: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (folders.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  title: 'No folders yet',
                  subtitle: 'Save looks, inspiration, or gift wishlists.',
                  icon: Icons.folder_rounded,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final folder = folders[index];
                      return _FolderCard(
                        folder: folder,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FolderDetailPage(folder: folder),
                          ),
                        ),
                      );
                    },
                    childCount: folders.length,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(title: 'Error', subtitle: '$e'),
    );
  }

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Folder name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true && controller.text.trim().isNotEmpty) {
      await ref.read(appRepositoryProvider).createFolder(
            name: controller.text.trim(),
          );
      ref.invalidate(foldersProvider);
    }
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder, required this.onTap});

  final Folder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCover = folder.coverUrl != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasCover ? null : AppColors.selectedNav,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: Border.all(color: AppColors.border),
          image: hasCover
              ? DecorationImage(
                  image: NetworkImage(folder.coverUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.28),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.bookmark_rounded,
              color: hasCover ? AppColors.white : AppColors.accent,
            ),
            const SizedBox(height: 4),
            Text(
              folder.name,
              style: TextStyle(
                color: hasCover ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderDetailPage extends ConsumerStatefulWidget {
  const FolderDetailPage({super.key, required this.folder});

  final Folder folder;

  @override
  ConsumerState<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends ConsumerState<FolderDetailPage> {
  late Future<List<FolderItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    _itemsFuture =
        ref.read(appRepositoryProvider).getFolderItems(widget.folder.id);
  }

  Future<void> _addItem() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final repo = ref.read(appRepositoryProvider);
    final userId = ref.read(currentProfileProvider)?.id ?? 'demo';
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final url = await repo.uploadMedia(
      bucket: 'folder-items',
      path: path,
      bytes: bytes,
      contentType: 'image/jpeg',
    );
    await repo.addFolderItem(folderId: widget.folder.id, imageUrl: url);
    setState(_loadItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<FolderItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Folder is empty',
              subtitle: 'Add photos to this folder.',
              icon: Icons.image_outlined,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(item.imageUrl, fit: BoxFit.cover),
                    if (item.caption.isNotEmpty)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Text(
                          item.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(color: Colors.black)],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
