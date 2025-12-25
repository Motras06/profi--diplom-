// lib/widgets/specialist/profile_tab/profile_header.dart
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? displayName;
  final String? specialty;
  final String? about;
  final String? photoUrl;

  const ProfileHeader({
    super.key,
    this.displayName,
    this.specialty,
    this.about,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 80,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null
              ? Text(
                  displayName?[0].toUpperCase() ?? 'С',
                  style: TextStyle(fontSize: 64, color: colorScheme.primary),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          displayName ?? 'Специалист',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Text('Специалист', style: TextStyle(fontSize: 18, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(
          specialty ?? 'Специальность не указана',
          style: const TextStyle(fontSize: 16, color: Colors.teal),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('О себе', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  about?.isNotEmpty == true
                      ? about!
                      : 'Расскажите о своём опыте, преимуществах и подходе к работе',
                  style: TextStyle(fontSize: 16, color: about?.isNotEmpty == true ? null : Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}