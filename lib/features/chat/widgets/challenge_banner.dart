import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/challenge.dart';
import '../../../shared/repositories/app_repository.dart';

/// Banner that surfaces the current month's challenge inside the chat/feed.
/// Shows the theme, prize pool, entry progress, and an "Enter" CTA.
class ChallengeBanner extends ConsumerWidget {
  const ChallengeBanner({super.key, required this.challenge, this.compact = false});

  final MonthlyChallenge challenge;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.black,
        image: challenge.coverUrl != null
            ? DecorationImage(
                image: NetworkImage(challenge.coverUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.45),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'MONTHLY CHALLENGE',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (challenge.prizePoolCents > 0)
                Text(
                  '\$${challenge.prizePoolDollars.toStringAsFixed(0)} fund',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            challenge.title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (!compact && challenge.theme.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              challenge.theme,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                '${challenge.entryCount} entries this month',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _EnterButton(challenge: challenge),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnterButton extends ConsumerWidget {
  const _EnterButton({required this.challenge});

  final MonthlyChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entered = challenge.enteredByMe;
    return GestureDetector(
      onTap: entered
          ? null
          : () async {
              await ref
                  .read(appRepositoryProvider)
                  .enterChallenge(challenge.id);
              ref.invalidate(currentChallengeProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You joined the challenge!')),
                );
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: entered ? Colors.white24 : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          entered ? 'Joined ✓' : 'Enter',
          style: TextStyle(
            color: entered ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
