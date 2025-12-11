import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Stream<List<Map<String, dynamic>>> _usersStream;
  //late String? currentUserName;

  @override
  void initState() {
    super.initState();
    _usersStream = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (Supabase.instance.client.auth.currentUser?.email ?? '').isNotEmpty
              ? 'Chats of ${Supabase.instance.client.auth.currentUser?.email}'
              : 'Chats',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _usersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;

          final otherUsers = users
              .where((u) => u['id'] != currentUserId)
              .toList();
          final currentUserName = users
              .where((u) => u['id'] == currentUserId)
              .first['username'];

          return ListView.builder(
            itemCount: otherUsers.length,
            itemBuilder: (context, index) {
              final user = otherUsers[index];
              return ListTile(
                title: Text(user['username'] ?? 'Unknown'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) {
                        return ChatScreen(
                          receiverId: user['id'],
                          currentUserName: currentUserName,
                          receiverName: user['username'],
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
