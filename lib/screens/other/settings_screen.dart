// lib/screens/other/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Уведомления',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          SwitchListTile(
            title: const Text('Push-уведомления'),
            subtitle: const Text('О новых сообщениях и заказах'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Email-уведомления'),
            subtitle: const Text('О важных событиях в приложении'),
            value: false,
            onChanged: (val) {},
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Конфиденциальность',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          ListTile(
            title: const Text('Удалить аккаунт'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Удаление аккаунта (в разработке)')),
              );
            },
          ),
          const Divider(),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'О приложении',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          ListTile(
            title: const Text('Версия приложения'),
            subtitle: const Text('1.0.0'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие политики (в разработке)')),
              );
            },
          ),
          ListTile(
            title: const Text('Условия использования'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Открытие условий (в разработке)')),
              );
            },
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Найди Мастера © 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}