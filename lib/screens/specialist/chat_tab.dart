// lib/screens/specialist/chat_tab.dart
import 'package:flutter/material.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Чаты с заказчиками',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь будет список активных диалогов\nс клиентами, которые интересовались вашими услугами',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('А')),
                title: Text('Алексей Иванов'),
                subtitle: Text('Интересует ремонт ванной...'),
                trailing: Text('14:32'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('М')),
                title: Text('Мария Петрова'),
                subtitle: Text('Сколько стоит замена проводки?'),
                trailing: Text('Вчера'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}