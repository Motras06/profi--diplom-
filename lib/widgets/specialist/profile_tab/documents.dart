// lib/widgets/specialist/profile_tab/documents.dart
import 'package:flutter/material.dart';

class SpecialistDocuments extends StatelessWidget {
  const SpecialistDocuments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои документы'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 32),
              const Text(
                'У вас нет загруженных документов',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Добавьте сертификаты, дипломы или лицензии,\nчтобы повысить доверие клиентов',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Загрузка документов (в разработке)')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Добавить документ'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}