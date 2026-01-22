// lib/screens/specialist/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class SpecialistChatScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String? clientPhoto;
  final bool isOnline;

  const SpecialistChatScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    this.clientPhoto,
    this.isOnline = false,
  });

  @override
  State<SpecialistChatScreen> createState() => _SpecialistChatScreenState();
}

class _SpecialistChatScreenState extends State<SpecialistChatScreen> {
  final supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _currentUserId;
  String? _clientId;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isUserBlacklisted = false;

  RealtimeChannel? _channel; // сохраняем для отписки

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _currentUserId = supabase.auth.currentUser?.id;
    _clientId = widget.clientId;

    if (_currentUserId == null || _clientId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка: не удалось определить участников чата'),
          ),
        );
      }
      return;
    }

    debugPrint(
      'SpecialistChatScreen: инициализация чата | user=$_currentUserId → client=$_clientId',
    );

    await _checkIfBlacklisted();
    await _loadInitialMessages();
    await _markMessagesAsRead();

    // Подписка на realtime
    _channel = supabase
        .channel('chat:${_currentUserId}_$_clientId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            final sender = newMsg['sender_id'] as String?;
            final receiver = newMsg['receiver_id'] as String?;

            if ((sender == _currentUserId && receiver == _clientId) ||
                (sender == _clientId && receiver == _currentUserId)) {
              if (!_messages.any((m) => m['id'] == newMsg['id'])) {
                debugPrint(
                  'Realtime: новое сообщение id=${newMsg['id']} от $sender',
                );
                if (mounted) {
                  setState(() {
                    _messages.add(newMsg);
                  });
                  _scrollToBottom();
                }
              }

              // УБРАЛИ: _markSingleMessageAsRead — это и вызывало цикл
              // Пометка прочитанных уже сделана в _markMessagesAsRead при открытии
            }
          },
        )
        .subscribe();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialMessages() async {
    debugPrint('Загрузка истории сообщений');
    try {
      final messages = await supabase
          .from('chat_messages')
          .select()
          .or(
            'and(sender_id.eq.$_currentUserId,receiver_id.eq.$_clientId),'
            'and(sender_id.eq.$_clientId,receiver_id.eq.$_currentUserId)',
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

  Future<void> _checkIfBlacklisted() async {
    try {
      final res = await supabase
          .from('blacklists')
          .select('id')
          .eq('specialist_id', _currentUserId!)
          .eq('blacklisted_user_id', _clientId!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isUserBlacklisted = res != null;
        });
        debugPrint('Клиент в чёрном списке: $_isUserBlacklisted');
      }
    } catch (e) {
      debugPrint('Ошибка проверки чёрного списка: $e');
    }
  }

  Future<void> _addToBlacklist() async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить в чёрный список'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Вы уверены, что хотите заблокировать ${widget.clientName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Причина (обязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Укажите причину')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('blacklists').insert({
        'specialist_id': _currentUserId,
        'blacklisted_user_id': _clientId,
        'reason': reasonCtrl.text.trim(),
      });

      if (mounted) {
        setState(() => _isUserBlacklisted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пользователь добавлен в чёрный список'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await supabase
          .from('chat_messages')
          .update({'read': true})
          .eq('sender_id', _clientId!)
          .eq('receiver_id', _currentUserId!)
          .eq('read', false);
      debugPrint('Все сообщения от клиента помечены как прочитанные');
    } catch (e) {
      debugPrint('Ошибка пометки всех сообщений: $e');
    }
  }

  Future<void> _markSingleMessageAsRead(int messageId) async {
    try {
      await supabase
          .from('chat_messages')
          .update({'read': true})
          .eq('id', messageId)
          .eq('sender_id', _clientId!)
          .eq('receiver_id', _currentUserId!);
      debugPrint('Сообщение id=$messageId помечено как прочитанное');
    } catch (e) {
      debugPrint('Ошибка пометки одного сообщения: $e');
    }
  }

  void _addMessage(Map<String, dynamic> newMsg) {
    if (!mounted) return;

    // Защита от дублей
    if (_messages.any((m) => m['id'] == newMsg['id'])) {
      debugPrint('Дубль сообщения id=${newMsg['id']} → не добавляем');
      return;
    }

    debugPrint(
      'Добавлено сообщение id=${newMsg['id']} от ${newMsg['sender_id']}',
    );

    setState(() {
      _messages.add(newMsg);
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    debugPrint('Отправка сообщения: "$text"');

    try {
      await supabase.from('chat_messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': _clientId,
        'message': text,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'read': false,
      });

      _messageController.clear();
    } catch (e) {
      debugPrint('Ошибка отправки: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.clientPhoto != null
                  ? NetworkImage(widget.clientPhoto!)
                  : null,
              child: widget.clientPhoto == null
                  ? Text(
                      widget.clientName.isNotEmpty
                          ? widget.clientName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 16),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.clientName, style: const TextStyle(fontSize: 18)),
                if (widget.isOnline)
                  Text(
                    'В сети',
                    style: TextStyle(fontSize: 12, color: Colors.green[300]),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          if (!_isUserBlacklisted)
            IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              tooltip: 'Добавить в чёрный список',
              onPressed: _addToBlacklist,
            ),
        ],
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
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey[600],
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
    _channel?.unsubscribe();
    debugPrint('SpecialistChatScreen dispose: отписка от канала выполнена');

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
