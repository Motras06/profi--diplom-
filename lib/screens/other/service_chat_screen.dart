// lib/screens/other/chat_screen.dart
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

    // Загружаем начальные сообщения (последние 50, например)
    await _loadInitialMessages();

    // Подписываемся на новые сообщения в обоих направлениях
    supabase
        .channel('chat:${_currentUserId}_$_specialistId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: _currentUserId,
          ),
          callback: (payload) {
            if (payload.newRecord['receiver_id'] == _specialistId) {
              _addMessage(payload.newRecord);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: _specialistId,
          ),
          callback: (payload) {
            if (payload.newRecord['receiver_id'] == _currentUserId) {
              _addMessage(payload.newRecord);
            }
          },
        )
        .subscribe();

    setState(() => _isLoading = false);
  }

  Future<void> _loadInitialMessages() async {
    final messages = await supabase
        .from('chat_messages')
        .select()
        .or(
          'and(sender_id.eq.$_currentUserId,receiver_id.eq.$_specialistId),'
          'and(sender_id.eq.$_specialistId,receiver_id.eq.$_currentUserId)'
        )
        .order('timestamp', ascending: true)
        .limit(50); // можно увеличить или сделать пагинацию

    setState(() {
      _messages = List<Map<String, dynamic>>.from(messages);
    });

    _scrollToBottom(animate: false);
  }

  void _addMessage(Map<String, dynamic> newMsg) {
    setState(() {
      _messages.add(newMsg);
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await supabase.from('chat_messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': _specialistId,
        'message': text,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'read': false,
      });

      _messageController.clear();
      // сообщение придёт через realtime
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки: $e')),
        );
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
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
    final date = DateTime.parse(timestamp).toLocal();
    return DateFormat('HH:mm').format(date);
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}