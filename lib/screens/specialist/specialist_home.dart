// lib/screens/auth/specialist_home.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import '../../services/supabase_service.dart';

class SpecialistHome extends StatelessWidget {
  final String displayName;

  const SpecialistHome({super.key, required this.displayName});

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
            const Icon(Icons.handyman, size: 80, color: Color(0xFF009999)),
            const SizedBox(height: 24),
            Text(
              'Привет, $displayName!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Роль: Специалист',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
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