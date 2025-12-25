// lib/screens/specialist/services_tab.dart
import 'package:flutter/material.dart';

class ServicesTab extends StatelessWidget {
  final String displayName;

  const ServicesTab({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            Text(
              'Мои услуги, $displayName',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь будет:\n• Список ваших созданных услуг\n• Кнопка "Добавить услугу"\n• Редактирование/удаление услуг\n• Поиск и фильтры',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: переход на экран создания услуги
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Создание услуги (в разработке)')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
            ),
          ],
        ),
      ),
    );
  }
}