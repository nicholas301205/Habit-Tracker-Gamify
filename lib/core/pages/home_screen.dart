import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// COMPONENTS
import 'package:habbit_tracker_gamify/core/components/home_dashboard.dart';

// PAGES
import 'habit_list_screen.dart';
import 'stats_screen.dart';
import 'achievement_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    HomeDashboard(),
    HabitListScreen(),
    StatsScreen(),
    AchievementScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Habit Tracker"),
        actions: [
          /// 🔥 BUTTON AI (PENTING)
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: "AI Assistant",
            onPressed: () {
              context.push('/ai');
            },
          ),
        ],
      ),

      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_outlined),
            activeIcon: Icon(Icons.list),
            label: 'Habits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Badge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),

      /// 🔥 OPTIONAL: Floating AI Button (lebih keren)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/ai');
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}