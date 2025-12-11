import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://djpzzwjxjlslnkgstgfk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcHp6d2p4amxzbG5rZ3N0Z2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNTI5ODYsImV4cCI6MjA4MDgyODk4Nn0.wQsV7inD7QjuAh-tgHUV6Z7jJUQ1PXPiQ4_ott_3raY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  //const MyApp({super.key});
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      home: Supabase.instance.client.auth.currentSession == null
          ? const AuthScreen()
          : const ChatListScreen(),
    );
  }
}
