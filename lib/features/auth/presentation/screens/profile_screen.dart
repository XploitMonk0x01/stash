import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/auth_repository.dart';
import '../../../links/presentation/providers/link_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final userAsync = ref.watch(currentUserProvider);
    final linkCountAsync = ref.watch(linkCountProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: userAsync.when(
                data: (user) {
                  if (authUser == null && user == null) {
                    return const Text('Not signed in');
                  }

                  final name = (user?.name.isNotEmpty ?? false)
                      ? user!.name
                      : (authUser?.displayName ?? '');
                  final email = (user?.email.isNotEmpty ?? false)
                      ? user!.email
                      : (authUser?.email ?? '');
                  final photoUrl = (user?.photoUrl?.isNotEmpty ?? false)
                      ? user!.photoUrl
                      : authUser?.photoURL;

                  return Column(
                    children: [
                      // Avatar
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, e, st) => const Icon(
                                    Icons.person_rounded,
                                    size: 36,
                                    color: AppColors.accent,
                                  ),
                                ),
                              )
                            : Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.isNotEmpty ? name : 'Unnamed',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Text('Failed to load profile'),
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text('Links Saved', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  linkCountAsync.when(
                    data: (count) => Text(
                      '$count',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, st) => const Text('—'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings list
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  // Theme toggle
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.accent,
                    ),
                    title: const Text('Dark Mode'),
                    trailing: Switch.adaptive(
                      value: themeMode == ThemeMode.dark,
                      activeTrackColor: AppColors.accent,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),

                  // Sign out
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Sign Out'),
                    onTap: () => _showSignOutDialog(context, ref),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),

                  // Delete account
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.error),
                    title: const Text('Delete Account',
                        style: TextStyle(color: AppColors.error)),
                    onTap: () => _showDeleteAccountDialog(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // App version
            Text(
              'Stash v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('You will need to sign in again to access your links.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth/sign-in');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all saved links. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authRepositoryProvider).deleteAccount();
                if (context.mounted) context.go('/auth/sign-in');
              } catch (e) {
                if (context.mounted) {
                  SnackbarUtils.showError(
                    context,
                    'Failed to delete account. You may need to re-authenticate.',
                  );
                }
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
