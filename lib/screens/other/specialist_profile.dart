// lib/screens/other/specialist_profile.dart
import 'package:flutter/material.dart';

class SpecialistProfileScreen extends StatelessWidget {
  final Map<String, dynamic> specialist;

  const SpecialistProfileScreen({super.key, required this.specialist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(specialist['display_name'] ?? 'Профиль мастера'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: specialist['photo_url'] != null ? NetworkImage(specialist['photo_url']) : null,
              child: specialist['photo_url'] == null
                  ? Text(
                      (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'М',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              specialist['display_name'] ?? 'Мастер',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (specialist['specialty'] != null)
              Text(
                specialist['specialty'],
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            const SizedBox(height: 24),
            if (specialist['about'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('О себе', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(specialist['about'], style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            const Text(
              'Здесь будут отзывы, услуги и кнопка "Написать"',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}