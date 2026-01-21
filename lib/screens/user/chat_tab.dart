// lib/widgets/user/chat_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../screens/other/service_chat_screen.dart'; // твой чат-экран

class UserChatTab extends StatefulWidget {
  const UserChatTab({super.key});

  @override
  State<UserChatTab> createState() => _UserChatTabState();
}

class _UserChatTabState extends State<UserChatTab> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _chatPreviews = [];
  List<Map<String, dynamic>> _filteredPreviews = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadChatPreviews();

    // Подписка на новые сообщения
    supabase
        .channel('user-chats:${supabase.auth.currentUser?.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: supabase.auth.currentUser?.id,
          ),
          callback: (payload) {
            _loadChatPreviews();
                    },
        )
        .subscribe();

    // Реактивный поиск
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        if (query.isEmpty) {
          _filteredPreviews = List.from(_chatPreviews);
        } else {
          _filteredPreviews = _chatPreviews
              .where((chat) =>
                  (chat['specialistName'] as String?)?.toLowerCase().contains(query) ?? false)
              .toList();
        }
      });
    });
  }

  Future<void> _loadChatPreviews() async {
    setState(() => _isLoading = true);

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Получаем все сообщения текущего пользователя (отправленные и полученные)
      final messagesResponse = await supabase
          .from('chat_messages')
          .select('''
            id, sender_id, receiver_id, message, timestamp, read
          ''')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('timestamp', ascending: false);

      // Собираем уникальные собеседники
      final Map<String, Map<String, dynamic>> previewsMap = {};

      // 1. Собираем все возможные ID собеседников
      final Set<String> otherIds = {};
      for (final msg in messagesResponse) {
        final otherId = msg['sender_id'] == currentUserId ? msg['receiver_id'] : msg['sender_id'];
        otherIds.add(otherId as String);
      }

      // 2. Подгружаем профили всех собеседников одним запросом
      final profilesResponse = await supabase
          .from('profiles')
          .select('id, display_name, photo_url')
          .inFilter('id', otherIds.toList());

      final profilesMap = {for (var p in profilesResponse) p['id'] as String: p};

      // 3. Группируем сообщения по собеседнику
      for (final msg in messagesResponse) {
        final isSentByMe = msg['sender_id'] == currentUserId;
        final otherId = isSentByMe ? msg['receiver_id'] : msg['sender_id'];
        final otherProfile = profilesMap[otherId] ?? {};

        if (!previewsMap.containsKey(otherId)) {
          previewsMap[otherId] = {
            'specialistId': otherId,
            'specialistName': otherProfile['display_name'] ?? 'Мастер',
            'specialistPhoto': otherProfile['photo_url'],
            'lastMessage': msg['message'],
            'timestamp': msg['timestamp'],
            'unreadCount': isSentByMe ? 0 : (msg['read'] == false ? 1 : 0),
            'isOnline': false, // заглушка
          };
        } else {
          final existing = previewsMap[otherId]!;
          final msgTime = DateTime.parse(msg['timestamp'] as String);
          final existingTime = DateTime.parse(existing['timestamp'] as String);

          if (msgTime.isAfter(existingTime)) {
            existing['lastMessage'] = msg['message'];
            existing['timestamp'] = msg['timestamp'];
            if (!isSentByMe && msg['read'] == false) {
              existing['unreadCount'] = (existing['unreadCount'] ?? 0) + 1;
            }
          }
        }
      }

      final previewsList = previewsMap.values.toList()
        ..sort((a, b) => DateTime.parse(b['timestamp'] as String).compareTo(DateTime.parse(a['timestamp'] as String)));

      setState(() {
        _chatPreviews = previewsList;
        _filteredPreviews = List.from(previewsList);
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Ошибка чатов: $e\n$stack');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки чатов: $e')),
        );
      }
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    } else if (date.year == now.year) {
      return DateFormat('dd MMM').format(date);
    } else {
      return DateFormat('dd.MM.yy').format(date);
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
                  hintText: 'Поиск по имени мастера...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text('Чаты'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _filteredPreviews = List.from(_chatPreviews);
                });
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChatPreviews,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredPreviews.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? 'Нет совпадений' : 'Нет активных чатов',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSearching
                              ? 'Попробуйте другое имя'
                              : 'Начните общение с мастером через его услугу',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPreviews.length,
                    itemBuilder: (context, index) {
                      final chat = _filteredPreviews[index];
                      final unread = chat['unreadCount'] as int? ?? 0;
                      final time = _formatTimestamp(chat['timestamp']);

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: chat['specialistPhoto'] != null
                                  ? NetworkImage(chat['specialistPhoto'])
                                  : null,
                              child: chat['specialistPhoto'] == null
                                  ? Text(
                                      (chat['specialistName'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                            if (chat['isOnline'] == true)
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
                          chat['specialistName'] ?? 'Мастер',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          chat['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              time,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceChatScreen(
                                specialist: {
                                  'id': chat['specialistId'],
                                  'display_name': chat['specialistName'],
                                  'photo_url': chat['specialistPhoto'],
                                  'specialty': '', // можно подгрузить из profiles
                                },
                              ),
                            ),
                          ).then((_) => _loadChatPreviews());
                        },
                      );
                    },
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}