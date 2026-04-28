import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habbit_tracker_gamify/providers/theme_provider.dart';
import 'package:habbit_tracker_gamify/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const SizedBox();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 20),
              _XPCard(user: user),
              const SizedBox(height: 20),
              _SettingsSection(),
              const SizedBox(height: 20),
              _DangerZone(),
            ],
          );
        },
      ),
    );
  }
}

//
// 🔹 PROFILE HEADER
//
class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.08),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: color,
            child: Text(
              user.username.isNotEmpty
                  ? user.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.username,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

//
// 🔹 XP CARD (GAMIFIED)
//
class _XPCard extends StatelessWidget {
  final dynamic user;
  const _XPCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Level ${user.level}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: user.xpProgress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Text(
            '${user.xp} XP • ${user.xpToNextLevel} XP to next level',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

//
// 🔹 SETTINGS SECTION
//
class _SettingsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Test Notification'),
            subtitle: const Text('Cek apakah notifikasi bekerja'),
            onTap: () async {
              await NotificationService.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifikasi dikirim!'),
                  ),
                );
              }
            },
          ),
          const Divider(height: 0),
          SwitchListTile(
            value: ref.watch(themeModeProvider) ==
                ThemeMode.dark,
            onChanged: (value) {
              ref
                  .read(themeModeProvider.notifier)
                  .state = value
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
            title: const Text('Dark Mode'),
            secondary:
                const Icon(Icons.dark_mode_outlined),
          ),
        ],
      ),
    );
  }
}

//
// 🔹 DANGER ZONE (LOGOUT)
//
class _DangerZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon:
                const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              await ref
                  .read(authNotifierProvider.notifier)
                  .logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: OutlinedButton.styleFrom(
              side:
                  const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(
                  vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}