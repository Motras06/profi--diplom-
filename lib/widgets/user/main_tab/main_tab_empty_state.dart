import 'package:flutter/material.dart';

class MainTabEmptyState extends StatelessWidget {
  const MainTabEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Услуги не найдены', style: TextStyle(fontSize: 17)),
          const SizedBox(height: 6),
          Text(
            'Попробуйте убрать фильтры или изменить запрос',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}