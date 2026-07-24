import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/login_page.dart';
import '../../features/campaigns/upload_wizard/upload_wizard_page.dart';
import '../../features/chat/chat_room_page.dart';
import '../../features/feed/home_feed_page.dart';
import '../../features/folders/folders_page.dart';
import '../../features/profile/profile_page.dart';
import '../../shared/repositories/app_repository.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  static const items = [
    (icon: Icons.grid_view_rounded, label: 'Discover'),
    (icon: Icons.bookmark_rounded, label: 'Boards'),
    (icon: Icons.add_box_rounded, label: 'Create'),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'osland.',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        ),
        actions: [
          if (profile != null)
            IconButton(
              onPressed: () => context.push('/profile'),
              icon: CircleAvatar(
                radius: 16,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(profile.displayName.characters.first.toUpperCase())
                    : null,
              ),
            ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final selected = widget.navigationShell.currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.navigationShell.goBranch(
                      index,
                      initialLocation: index ==
                          widget.navigationShell.currentIndex,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.selectedNav
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: selected
                            ? Row(
                                key: ValueKey(index),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    items[index].icon,
                                    size: 30,
                                    color: AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    items[index].label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              )
                            : Icon(
                                items[index].icon,
                                size: 24,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final profile = authState.valueOrNull;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (isLoading) return null;
      if (profile == null && !isAuthRoute) return '/auth/login';
      if (profile != null && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (_, __) => const SignUpPage(),
      ),
      GoRoute(
        path: '/auth/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfilePage(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PostDetailPage(postId: id);
        },
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return ChatRoomPage(roomId: roomId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeFeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/folders',
                builder: (_, __) => const FoldersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/campaign',
                builder: (_, __) => const UploadWizardPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
