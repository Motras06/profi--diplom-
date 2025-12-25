// lib/widgets/user/profile_tab/profile_view.dart
import 'package:flutter/material.dart';

import '../../../screens/other/settings_screen.dart';
import 'service_history.dart'; // Новый экран истории

class ProfileView extends StatelessWidget {
  final String? displayName;
  final String? photoUrl;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const ProfileView({
    super.key,
    this.displayName,
    this.photoUrl,
    required this.onEdit,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    displayName?[0].toUpperCase() ?? 'П',
                    style: TextStyle(fontSize: 64, color: colorScheme.primary),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            displayName ?? 'Пользователь',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const Text('Пользователь', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать профиль'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ServiceHistory()),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('История заказов'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings),
            label: const Text('Настройки'),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Выйти из аккаунта', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}