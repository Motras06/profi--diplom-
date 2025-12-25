// lib/screens/user/chat_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/other/chat.dart';


class UserChatTab extends StatelessWidget {
  const UserChatTab({super.key});

  // Затычки — фейковые чаты с мастерами
  static const List<Map<String, dynamic>> _fakeChats = [
    {
      'masterName': 'Алексей Иванов',
      'masterInitial': 'А',
      'lastMessage': 'Могу приехать завтра в 14:00 для замера',
      'timestamp': '14:32',
      'unreadCount': 0,
      'isOnline': true,
    },
    {
      'masterName': 'Дмитрий Петров',
      'masterInitial': 'Д',
      'lastMessage': 'Да, работаю с такими материалами. Можем обсудить детали?',
      'timestamp': 'Вчера',
      'unreadCount': 1,
      'isOnline': false,
    },
    {
      'masterName': 'Сергей Морозов',
      'masterInitial': 'С',
      'lastMessage': 'Сколько примерно будет стоить ремонт кухни 10 м²?',
      'timestamp': 'Пн',
      'unreadCount': 3,
      'isOnline': true,
    },
    {
      'masterName': 'Ольга Кузнецова',
      'masterInitial': 'О',
      'lastMessage': 'Спасибо за быстрый ремонт! Рекомендую всем 👍',
      'timestamp': '19 дек',
      'unreadCount': 0,
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Поиск чатов (в разработке)')),
              );
            },
          ),
        ],
      ),
      body: _fakeChats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Нет активных чатов', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Начните общение с мастером через его услугу',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _fakeChats.length,
              itemBuilder: (context, index) {
                final chat = _fakeChats[index];

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          chat['masterInitial'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      if (chat['isOnline'])
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    chat['masterName'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    chat['lastMessage'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat['timestamp'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (chat['unreadCount'] > 0) const SizedBox(height: 6),
                      if (chat['unreadCount'] > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${chat['unreadCount']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    // Переход в реальный чат с мастером
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          clientName: chat['masterName'],
                          clientInitial: chat['masterInitial'],
                          isOnline: chat['isOnline'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}