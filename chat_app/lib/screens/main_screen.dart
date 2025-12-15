import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_list_screen.dart';
import 'ai_assistant_screen.dart';
import 'settings_screen.dart';

/// Main screen container with bottom navigation bar.
/// 
/// Contains two tabs:
/// - Chats: Existing chat list screen
/// - Chat Assist: New AI command interface
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const AIAssistantScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageCircle),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.sparkles),
            label: 'Chat Assist',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.cog),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}



