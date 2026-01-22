// lib/screens/specialist/chat_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/other/chat_specialist.dart'; // SpecialistChatScreen
import '../../services/supabase_service.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _filteredChats = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);

    try {
      final specialistId = supabase.auth.currentUser?.id;
      if (specialistId == null) throw Exception('Не авторизован');

      // 1. Получаем ID пользователей из чёрного списка
      final blacklistRes = await supabase
          .from('blacklists')
          .select('blacklisted_user_id')
          .eq('specialist_id', specialistId);

      final blacklistedIds = blacklistRes
          .map((e) => e['blacklisted_user_id'] as String)
          .toSet();

      // 2. Загружаем сообщения
      final response = await supabase
          .from('chat_messages')
          .select('''
            id,
            sender_id,
            receiver_id,
            message,
            timestamp,
            read,
            profiles!sender_id (display_name, photo_url)
          ''')
          .eq('receiver_id', specialistId)
          .order('timestamp', ascending: false);

      final Map<String, Map<String, dynamic>> chatMap = {};

      for (final msg in response) {
        final senderId = msg['sender_id'] as String? ?? '';
        if (senderId.isEmpty) continue;

        // Пропускаем чаты с пользователями из чёрного списка
        if (blacklistedIds.contains(senderId)) continue;

        final senderProfile = msg['profiles'] as Map<String, dynamic>? ?? {};

        DateTime? msgTime;
        String formattedTime = '—';
        try {
          final tsStr = msg['timestamp'] as String?;
          if (tsStr != null && tsStr.isNotEmpty) {
            msgTime = DateTime.parse(tsStr);
            formattedTime = _formatTimestamp(tsStr);
          }
        } catch (e) {
          debugPrint('Некорректная дата в сообщении ${msg['id']}: $e');
        }

        if (!chatMap.containsKey(senderId)) {
          chatMap[senderId] = {
            'clientId': senderId,
            'clientName': (senderProfile['display_name'] as String? ?? 'Клиент').toLowerCase(),
            'clientNameOriginal': senderProfile['display_name'] as String? ?? 'Клиент',
            'clientPhoto': senderProfile['photo_url'] as String?,
            'lastMessage': msg['message'] as String? ?? '',
            'timestamp': formattedTime,
            'unreadCount': 0,
            'isOnline': false,
            'lastTimestamp': msgTime ?? DateTime(2000),
          };
        }

        final existing = chatMap[senderId]!;

        if (msgTime != null && msgTime.isAfter(existing['lastTimestamp'] as DateTime)) {
          existing['lastMessage'] = msg['message'] as String? ?? '';
          existing['timestamp'] = formattedTime;
          existing['lastTimestamp'] = msgTime;
        }

        if (msg['read'] == false) {
          existing['unreadCount'] = (existing['unreadCount'] as int) + 1;
        }
      }

      final allChats = chatMap.values.toList()
        ..sort((a, b) => (b['lastTimestamp'] as DateTime).compareTo(a['lastTimestamp'] as DateTime));

      setState(() {
        _chats = allChats;
        _filteredChats = allChats;
      });
    } catch (e, stack) {
      debugPrint('Ошибка загрузки чатов: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки чатов: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterChats() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredChats = List.from(_chats);
      } else {
        _filteredChats = _chats.where((chat) {
          return (chat['clientName'] as String).contains(query);
        }).toList();
      }
    });
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Вчера';
      } else if (diff.inDays < 7) {
        return ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][date.weekday - 1];
      } else {
        return '${date.day} ${[
          'янв', 'фев', 'мар', 'апр', 'май', 'июн',
          'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
        ][date.month - 1]}';
      }
    } catch (e) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Поиск по имени клиента...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (_) => _filterChats(),
              )
            : const Text('Чаты'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filterChats();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredChats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isNotEmpty ? 'Чаты не найдены' : 'Нет активных чатов',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'Попробуйте изменить запрос'
                            : 'Когда клиенты напишут — чаты появятся здесь',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.builder(
                    itemCount: _filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredChats[index];

                      final displayName = chat['clientNameOriginal'] as String;
                      final photoUrl = chat['clientPhoto'] as String?;
                      final lastMessage = chat['lastMessage'] as String;
                      final timestamp = chat['timestamp'] as String;
                      final unreadCount = chat['unreadCount'] as int;
                      final isOnline = chat['isOnline'] as bool;

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null
                                  ? Text(
                                      displayName[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            if (isOnline)
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
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              timestamp,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (unreadCount > 0) const SizedBox(height: 6),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SpecialistChatScreen(
                                clientId: chat['clientId'] as String,
                                clientName: displayName,
                                clientPhoto: photoUrl,
                                isOnline: isOnline,
                              ),
                            ),
                          ).then((_) => _loadChats());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}