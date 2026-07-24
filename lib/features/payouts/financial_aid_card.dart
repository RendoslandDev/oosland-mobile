import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/repositories/app_repository.dart';

/// Surfaces the creator's "Monthly Financial Aid" — cumulative monthly likes
/// converted into a proportional share of the creator fund.
class FinancialAidCard extends ConsumerWidget {
  const FinancialAidCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutAsync = ref.watch(myPayoutProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF181818), Color(0xFF2B2B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Monthly Financial Aid',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await ref.read(appRepositoryProvider).computeMonthlyPayouts();
                  ref.invalidate(myPayoutProvider);
                },
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white70, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          payoutAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => Text('Could not load: $e',
                style: const TextStyle(color: Colors.white70)),
            data: (payout) {
              final dollars = payout?.payoutDollars ?? 0;
              final likes = payout?.likeCount ?? 0;
              final pool = payout?.poolDollars ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${dollars.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'estimated for this month',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(label: 'Likes this month', value: '$likes'),
                      const SizedBox(width: 24),
                      _Stat(
                        label: 'Creator fund',
                        value: '\$${pool.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your share = fund × your likes ÷ all likes.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      ],
    );
  }
}
