// lib/widgets/user/profile_tab/profile_info.dart
import 'package:flutter/material.dart';

class ProfileInfo extends StatelessWidget {
  final String? displayName;
  final String? role;
  final String? specialty;
  final String? email;

  const ProfileInfo({
    super.key,
    this.displayName,
    this.role,
    this.specialty,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          displayName ?? 'Имя не указано',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        if (role != null) ...[
          const SizedBox(height: 6),
          Chip(
            label: Text(
              role == 'specialist' ? (specialty ?? 'Специалист') : 'Клиент',
            ),
            backgroundColor: role == 'specialist' ? Colors.blue.shade100 : colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          email ?? '—',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
        ),
      ],
    );
  }
}