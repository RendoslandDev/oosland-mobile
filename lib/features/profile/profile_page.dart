import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/profile.dart';
import '../../shared/repositories/app_repository.dart';
import '../../shared/widgets/phase_media_viewer.dart';
import '../payouts/financial_aid_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final giftsAsync = ref.watch(receivedGiftsProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(appRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: AppColors.selectedNav,
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.displayName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '@${profile.username}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Chip(label: Text(profile.role.label)),
                    if (profile.tier.label.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TierBadge(label: profile.tier.label),
                    ],
                  ],
                ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(profile.bio, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const FinancialAidCard(),
          const SizedBox(height: 24),
          _ActionRow(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () => _showEditProfile(context, ref, profile),
          ),
          _ActionRow(
            icon: Icons.campaign_outlined,
            title: 'My campaigns',
            onTap: () => _showCampaigns(context, ref),
          ),
          _ActionRow(
            icon: Icons.card_giftcard_outlined,
            title: 'Gifts received',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent gifts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          giftsAsync.when(
            data: (gifts) {
              if (gifts.isEmpty) {
                return const EmptyState(
                  title: 'No gifts yet',
                  subtitle: 'When someone gifts you, it appears here.',
                  icon: Icons.card_giftcard_outlined,
                );
              }
              return Column(
                children: gifts.take(5).map((gift) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      gift.giftTypeData?.icon ?? '🎁',
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(gift.giftTypeData?.name ?? gift.giftType),
                    subtitle: Text(gift.message.isEmpty ? 'No message' : gift.message),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCampaigns(BuildContext context, WidgetRef ref) async {
    final campaigns = await ref.read(campaignsProvider.future);
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Campaigns',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (campaigns.isEmpty)
            const Text('No campaigns yet.')
          else
            ...campaigns.map(
              (c) => ListTile(
                title: Text(c.title),
                subtitle: Text(c.theme),
                trailing: Chip(label: Text(c.status.name)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditProfile(
    BuildContext context,
    WidgetRef ref,
    profile,
  ) async {
    final nameController = TextEditingController(text: profile.displayName);
    final bioController = TextEditingController(text: profile.bio);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(appRepositoryProvider).updateProfile(
                        profile.copyWith(
                          displayName: nameController.text.trim(),
                          bio: bioController.text.trim(),
                        ),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
