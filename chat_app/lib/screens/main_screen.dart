import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'memories_screen.dart';
import 'reminders_screen.dart';
import 'lists_screen.dart';

/// Main screen container with bottom navigation bar.
///
/// Contains five tabs:
/// - Home: Dashboard overview with quick actions
/// - Chats: Chat conversations list
/// - Memories: Personal knowledge base
/// - Reminders: Time-based reminders
/// - Lists: Task lists and to-dos
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ChatListScreen(),
    MemoriesScreen(),
    RemindersScreen(),
    ListsScreen(),
  ];

  /// Allows child screens (e.g. Dashboard) to switch tabs.
  void switchTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Lists',
          ),
        ],
      ),
    );
  }
}
