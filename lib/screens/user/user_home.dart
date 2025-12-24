// lib/screens/auth/user_home.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import '../../services/supabase_service.dart';

class UserHome extends StatelessWidget {
  final String displayName;

  const UserHome({super.key, required this.displayName});

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Найди Мастера'),
        centerTitle: true,
        actions: [
          if (displayName != 'Гость')
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 80, color: Color(0xFF009999)),
            const SizedBox(height: 24),
            Text(
              'Привет, $displayName!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              displayName == 'Гость' ? 'Вы вошли как гость' : 'Роль: Пользователь',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            if (displayName != 'Гость')
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Выйти из аккаунта'),
              ),
          ],
        ),
      ),
    );
  }
}