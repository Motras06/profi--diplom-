import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:profi/screens/other/specialist_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

class _SpecialistChatScreenState extends State<SpecialistChatScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _currentUserId;
  String? _clientId;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isUserBlacklisted = false;

  RealtimeChannel? _channel;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _initializeChat();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
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

    await _checkIfBlacklisted();
    await _loadInitialMessages();
    await _markMessagesAsRead();

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
                if (mounted) {
                  setState(() {
                    _messages.add(newMsg);
                  });
                  _scrollToBottom();
                  _animController.forward(from: 0.0);
                }
              }
            }
          },
        )
        .subscribe();

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadInitialMessages() async {
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

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(messages);
        });
        _scrollToBottom(animate: false);

        if (_messages.isNotEmpty) {
          _animController.forward(from: 0.0);
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки сообщений: $e');
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
        setState(() => _isUserBlacklisted = res != null);
      }
    } catch (e) {
      debugPrint('Ошибка проверки чёрного списка: $e');
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
    } catch (e) {
      debugPrint('Ошибка пометки сообщений: $e');
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
              decoration: InputDecoration(
                labelText: 'Причина (обязательно)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось отправить: $e')));
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(pos);
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

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Сообщение скопировано'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showMessageContextMenu(String messageText) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Действия с сообщением',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_rounded),
            title: const Text('Копировать'),
            onTap: () {
              _copyMessage(messageText);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SpecialistProfileScreen(
                  specialist: {
                    'id': widget.clientId,
                    'display_name': widget.clientName,
                    'photo_url': widget.clientPhoto,
                  },
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundImage: widget.clientPhoto != null
                      ? NetworkImage(widget.clientPhoto!)
                      : null,
                  child: widget.clientPhoto == null
                      ? Text(
                          widget.clientName.isNotEmpty
                              ? widget.clientName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clientName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.isOnline)
                        Text(
                          'В сети',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green[400],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (!_isUserBlacklisted)
            IconButton(
              icon: Icon(Icons.block_rounded, color: colorScheme.error),
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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      reverse: false,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['sender_id'] == _currentUserId;
                        final text = msg['message'] as String? ?? '';
                        final time = _formatTime(msg['timestamp'] as String?);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onLongPress: () {
                              if (text.isNotEmpty)
                                _showMessageContextMenu(text);
                            },
                            child: Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: Material(
                                  elevation: isMe ? 1 : 0.5,
                                  shadowColor: Colors.black.withOpacity(0.12),
                                  color: isMe
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          text,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: isMe
                                                    ? colorScheme
                                                          .onPrimaryContainer
                                                    : colorScheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          time,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: isMe
                                                    ? colorScheme
                                                          .onPrimaryContainer
                                                          .withOpacity(0.7)
                                                    : colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: _isUserBlacklisted
                                ? 'Пользователь в чёрном списке'
                                : 'Напишите сообщение...',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          enabled: !_isUserBlacklisted,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        onPressed: _isUserBlacklisted ? null : _sendMessage,
                        backgroundColor: _isUserBlacklisted
                            ? colorScheme.onSurface.withOpacity(0.38)
                            : colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 2,
                        shape: const CircleBorder(),
                        child: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
