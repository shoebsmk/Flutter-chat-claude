import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isSignUp = false;

  Future<void> _handleAuth() async {
    try {
      if (_isSignUp) {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {'username': _usernameController.text},
        );
        final userId = response.user?.id;
        if (userId != null) {
          await Supabase.instance.client.from('users').insert({
            'id': userId,
            'username': _usernameController.text,
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final existing = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('id', userId)
              .limit(1);
          if (existing is List && existing.isEmpty) {
            final email = _emailController.text;
            final username = email.split('@').first;
            await Supabase.instance.client.from('users').insert({
              'id': userId,
              'username': username,
            });
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          //MaterialPageRoute(builder: (_) => const ChatListScreen()),
          MaterialPageRoute(builder: (_) => const ChatListScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_isSignUp)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleAuth,
              child: Text(_isSignUp ? 'Sign Up' : 'Login'),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(
                _isSignUp
                    ? 'Already have an account? Login'
                    : 'Don\'t have an account? Sign Up',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
