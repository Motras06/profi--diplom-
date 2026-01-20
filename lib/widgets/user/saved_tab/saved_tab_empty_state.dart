// lib/widgets/user/saved_tab/saved_tab_empty_state.dart
import 'package:flutter/material.dart';

class SavedTabEmptyState extends StatelessWidget {
  const SavedTabEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Нет сохранённых услуг', style: TextStyle(fontSize: 17)),
          const SizedBox(height: 6),
          Text(
            'Сохраните услугу, нажав на закладку\nили измените фильтры',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}