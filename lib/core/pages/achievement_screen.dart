import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/services/badge_services.dart';
import '../../models/badge_model.dart';
import '../../providers/auth_provider.dart';

final badgeServiceProvider = Provider((ref) => BadgeService());

final userBadgesProvider = StreamProvider<List<BadgeModel>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(badgeServiceProvider).watchUserBadges(uid);
});

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievement'),
        centerTitle: true,
      ),
      body: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (badges) {
          final unlocked = badges.where((b) => b.isUnlocked).length;
          return CustomScrollView(
            slivers: [
              // Summary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('🏅', style: TextStyle(fontSize: 36)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$unlocked / ${badges.length} Badge',
                              style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              unlocked == 0
                                  ? 'Start completing habits to earn badges!'
                                  : 'Nice! Keep unlocking more badges!',
                              style: const TextStyle(
                                fontSize: 13, color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Badge grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BadgeTile(badge: badges[i]),
                    childCount: badges.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: badge.isUnlocked ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: badge.isUnlocked
              ? badge.color.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isUnlocked ? badge.color : Colors.grey.shade300,
            width: badge.isUnlocked ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badge.isUnlocked
                ? Text(badge.emoji, style: const TextStyle(fontSize: 40))
                : const Icon(Icons.lock_outline, size: 36, color: Colors.grey),
            const SizedBox(height: 10),
            Text(badge.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: badge.isUnlocked ? badge.color : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(badge.description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}