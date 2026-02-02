import 'package:flutter/material.dart';

class ProfileActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  const ProfileActions({
    super.key,
    required this.onEdit,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: const Text('Редактировать профиль'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.rate_review),
          label: const Text('Отзывы (в разработке)'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.description),
          label: const Text('Документы (в разработке)'),
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text(
            'Выйти из аккаунта',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}
