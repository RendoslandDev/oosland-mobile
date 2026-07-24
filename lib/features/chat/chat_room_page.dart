import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/theme/app_theme.dart';
import '../../shared/models/chat.dart';
import '../../shared/models/profile.dart';
import '../../shared/repositories/app_repository.dart';
import '../../shared/widgets/phase_media_viewer.dart';
import 'widgets/bulletin_space.dart';
import 'widgets/challenge_banner.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _composer = TextEditingController();

  // Optimistic like state, keyed by message id (realtime payloads omit counts).
  final _likedOverride = <String, bool>{};
  final _countDelta = <String, int>{};

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty) return;
    _composer.clear();
    await ref.read(appRepositoryProvider).sendMessage(widget.roomId, body);
  }

  Future<void> _toggleLike(ChatMessage m) async {
    final liked = _likedOverride[m.id] ?? m.likedByMe;
    setState(() {
      _likedOverride[m.id] = !liked;
      _countDelta[m.id] = (_countDelta[m.id] ?? 0) + (liked ? -1 : 1);
    });
    await ref.read(appRepositoryProvider).toggleMessageLike(m.id);
  }

  Future<void> _reply(ChatMessage m) async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${m.author?.displayName ?? 'message'}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your reply...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reply'),
          ),
        ],
      ),
    );
    if (sent == true && controller.text.trim().isNotEmpty) {
      await ref.read(appRepositoryProvider).sendMessage(
            widget.roomId,
            controller.text.trim(),
            parentId: m.id,
          );
    }
  }

  void _share(ChatMessage m) {
    Clipboard.setData(ClipboardData(text: m.body));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied — share it to grow the room')),
    );
  }

  Future<void> _giftRoomOwner(String ownerId) async {
    final giftTypes = await ref.read(giftTypesProvider.future);
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Send a gift to the room',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...giftTypes.map(
              (type) => ListTile(
                leading:
                    Text(type.icon, style: const TextStyle(fontSize: 28)),
                title: Text(type.name),
                trailing: Text('${type.pointValue} pts',
                    style: const TextStyle(color: AppColors.textSecondary)),
                onTap: () async {
                  await ref.read(appRepositoryProvider).sendGift(
                        recipientId: ownerId,
                        giftType: type.id,
                        roomId: widget.roomId,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${type.name} sent! ${type.icon}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(chatRoomProvider(widget.roomId));
    final messagesAsync = ref.watch(roomMessagesProvider(widget.roomId));
    final challengeAsync = ref.watch(currentChallengeProvider);
    final me = ref.watch(currentProfileProvider);

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, _) =>
          Scaffold(body: EmptyState(title: 'Room error', subtitle: '$e')),
      data: (room) {
        if (room == null) {
          return const Scaffold(body: EmptyState(title: 'Room not found'));
        }
        final challenge = challengeAsync.valueOrNull;
        final showChallenge =
            challenge != null && room.challengeId == challenge.id;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text(
                  'with @${room.owner?.username ?? 'creator'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _giftRoomOwner(room.ownerId),
                icon: const Icon(Icons.card_giftcard_rounded,
                    color: AppColors.accent),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent)),
                  error: (e, _) =>
                      EmptyState(title: 'Could not load chat', subtitle: '$e'),
                  data: (messages) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      children: [
                        if (showChallenge) ...[
                          ChallengeBanner(challenge: challenge, compact: true),
                          const SizedBox(height: 16),
                        ],
                        BulletinSpace(
                          roomId: room.id,
                          challengeId: room.challengeId,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Live chat',
                                style:
                                    TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            Text('${messages.length}',
                                style: const TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (messages.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Say hello to start the conversation.',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          )
                        else
                          ...messages.map((m) => _MessageTile(
                                message: m,
                                isMine: m.userId == me?.id,
                                liked: _likedOverride[m.id] ?? m.likedByMe,
                                likeCount:
                                    m.likeCount + (_countDelta[m.id] ?? 0),
                                onLike: () => _toggleLike(m),
                                onReply: () => _reply(m),
                                onShare: () => _share(m),
                              )),
                      ],
                    );
                  },
                ),
              ),
              _Composer(controller: _composer, onSend: _send),
            ],
          ),
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.isMine,
    required this.liked,
    required this.likeCount,
    required this.onLike,
    required this.onReply,
    required this.onShare,
  });

  final ChatMessage message;
  final bool isMine;
  final bool liked;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final author = message.author;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.selectedNav,
            backgroundImage:
                author?.avatarUrl != null ? NetworkImage(author!.avatarUrl!) : null,
            child: author?.avatarUrl == null
                ? Text(
                    (author?.displayName ?? '?').characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 13),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        author?.displayName ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    if (author?.tier.label.isNotEmpty ?? false) ...[
                      const SizedBox(width: 6),
                      TierBadge(label: author!.tier.label),
                    ],
                    if (message.createdAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        timeago.format(message.createdAt!, locale: 'en_short'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.accentSoft : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(message.body, style: const TextStyle(height: 1.3)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _LoopAction(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      label: '$likeCount',
                      color: liked ? AppColors.accent : AppColors.textSecondary,
                      onTap: onLike,
                    ),
                    const SizedBox(width: 18),
                    _LoopAction(
                      icon: Icons.mode_comment_outlined,
                      label: '${message.replyCount}',
                      onTap: onReply,
                    ),
                    const SizedBox(width: 18),
                    _LoopAction(
                      icon: Icons.ios_share_rounded,
                      label: 'Share',
                      onTap: onShare,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoopAction extends StatelessWidget {
  const _LoopAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(hintText: 'Message the room...'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.white,
                minimumSize: const Size(52, 52),
              ),
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
