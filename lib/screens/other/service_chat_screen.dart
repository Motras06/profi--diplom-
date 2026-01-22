// lib/screens/other/chat_screen.dart (или lib/screens/specialist/chat_screen.dart)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ServiceChatScreen extends StatefulWidget {
  final Map<String, dynamic> specialist;
  final Map<String, dynamic>? service;

  const ServiceChatScreen({
    super.key,
    required this.specialist,
    this.service,
  });

  @override
  State<ServiceChatScreen> createState() => _ServiceChatScreenState();
}

class _ServiceChatScreenState extends State<ServiceChatScreen> {
  final supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _currentUserId;
  String? _specialistId;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  RealtimeChannel? _channel; // сохраняем канал для отписки

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _currentUserId = supabase.auth.currentUser?.id;
    _specialistId = widget.specialist['id'] as String?;

    if (_currentUserId == null || _specialistId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: не удалось определить участников чата')),
        );
      }
      return;
    }

    debugPrint('Чат открыт: user=$_currentUserId → specialist=$_specialistId');

    // 1. Загружаем историю
    await _loadInitialMessages();

    // 2. Подписка на realtime (один канал + фильтрация внутри)
    _channel = supabase
        .channel('chat:${_currentUserId}_$_specialistId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            final sender = newMsg['sender_id'] as String?;
            final receiver = newMsg['receiver_id'] as String?;

            // Только сообщения между нами
            if ((sender == _currentUserId && receiver == _specialistId) ||
                (sender == _specialistId && receiver == _currentUserId)) {
              
              // Добавляем только если id ещё нет в списке
              if (!_messages.any((m) => m['id'] == newMsg['id'])) {
                debugPrint('Realtime: добавлено сообщение id=${newMsg['id']} от $sender');
                if (mounted) {
                  setState(() {
                    _messages.add(newMsg);
                  });
                  _scrollToBottom();
                }
              } else {
                debugPrint('Realtime: сообщение id=${newMsg['id']} уже существует → пропускаем');
              }
            }
          },
        )
        .subscribe();

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadInitialMessages() async {
    debugPrint('Загрузка истории сообщений');
    try {
      final messages = await supabase
          .from('chat_messages')
          .select()
          .or(
            'and(sender_id.eq.$_currentUserId,receiver_id.eq.$_specialistId),'
            'and(sender_id.eq.$_specialistId,receiver_id.eq.$_currentUserId)',
          )
          .order('timestamp', ascending: true)
          .limit(100);

      debugPrint('История загружена: ${messages.length} сообщений');

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(messages);
        });
        _scrollToBottom(animate: false);
      }
    } catch (e, stack) {
      debugPrint('Ошибка загрузки истории: $e\n$stack');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    debugPrint('Отправка сообщения: "$text"');

    try {
      await supabase.from('chat_messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': _specialistId,
        'message': text,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'read': false,
      });

      _messageController.clear();
      // Сообщение придёт через realtime и добавится один раз
    } catch (e, stack) {
      debugPrint('Ошибка отправки: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.specialist['display_name'] ?? 'Мастер';
    final specialty = widget.specialist['specialty'] ?? '';
    final photoUrl = widget.specialist['photo_url'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18)),
                if (specialty.isNotEmpty)
                  Text(
                    specialty,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _currentUserId;
                      final text = msg['message'] as String? ?? '';
                      final time = _formatTime(msg['timestamp'] as String?);

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Напишите сообщение...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    // Самое важное — отписываемся от канала!
    _channel?.unsubscribe();
    debugPrint('dispose: отписка от realtime-канала выполнена');

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}