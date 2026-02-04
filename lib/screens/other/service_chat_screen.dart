import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prowirksearch/screens/other/specialist_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:developer' as developer;

class ServiceChatScreen extends StatefulWidget {
  final Map<String, dynamic> specialist;
  final Map<String, dynamic>? service;

  const ServiceChatScreen({super.key, required this.specialist, this.service});

  @override
  State<ServiceChatScreen> createState() => _ServiceChatScreenState();
}

class _ServiceChatScreenState extends State<ServiceChatScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  String? _currentUserId;
  String? _specialistId;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

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
    _specialistId = widget.specialist['id'] as String?;

    if (_currentUserId == null || _specialistId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка: не удалось определить участников чата'),
          ),
        );
      }
      return;
    }

    await _loadInitialMessages();

    _channel = supabase
        .channel('private-chat:${_currentUserId}_$_specialistId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final newMsg = payload.newRecord;
            final sender = newMsg['sender_id'] as String?;
            final receiver = newMsg['receiver_id'] as String?;

            if ((sender == _currentUserId && receiver == _specialistId) ||
                (sender == _specialistId && receiver == _currentUserId)) {
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
            'and(sender_id.eq.$_currentUserId,receiver_id.eq.$_specialistId),'
            'and(sender_id.eq.$_specialistId,receiver_id.eq.$_currentUserId)',
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
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось отправить: $e')));
      }
    }
  }

  Future<void> _downloadAndOpenFile(
    String fileUrl,
    String displayFileName,
  ) async {
    debugPrint('→ Запрос на открытие файла: $fileUrl ($displayFileName)');

    if (fileUrl.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ссылка на файл отсутствует')),
        );
      }
      return;
    }

    try {
      final dio = Dio();

      String saveFileName = displayFileName.trim();
      if (saveFileName.isEmpty) {
        final uri = Uri.tryParse(fileUrl);
        saveFileName =
            uri?.pathSegments.last ??
            'file_${DateTime.now().millisecondsSinceEpoch}';
      }

      debugPrint('Имя файла для сохранения: $saveFileName');

      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Не удалось получить папку загрузок');
      }

      final savePath = '${directory.path}/$saveFileName';
      debugPrint('Путь сохранения: $savePath');

      await dio.download(fileUrl, savePath);
      debugPrint('Файл скачан: $savePath');

      final result = await OpenFilex.open(savePath);
      debugPrint('OpenFilex результат: ${result.type} — ${result.message}');

      if (mounted) {
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Не удалось открыть файл: ${result.message}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Файл открыт: $saveFileName')));
        }
      }
    } catch (e, stack) {
      debugPrint('Ошибка при скачивании/открытии файла: $e');
      developer.log('File open error', error: e, stackTrace: stack);

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

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_rounded,
      'doc' || 'docx' => Icons.description_rounded,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_rounded,
      'zip' || 'rar' => Icons.folder_zip_rounded,
      _ => Icons.attach_file_rounded,
    };
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

    final name = widget.specialist['display_name'] ?? 'Мастер';
    final specialty = widget.specialist['specialty'] ?? '';
    final photoUrl = widget.specialist['photo_url'] as String?;

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
                builder: (context) =>
                    SpecialistProfileScreen(specialist: widget.specialist),
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
                  foregroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
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
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (specialty.isNotEmpty)
                        Text(
                          specialty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                        final text = msg['message'] as String?;
                        final fileUrlRaw = msg['file_url'];
                        final fileUrl =
                            fileUrlRaw is String && fileUrlRaw.isNotEmpty
                            ? fileUrlRaw
                            : null;
                        final time = _formatTime(msg['timestamp'] as String?);

                        final hasFile = fileUrl != null;
                        final hasText = text != null && text.trim().isNotEmpty;

                        final displayFileName = hasFile
                            ? Uri.tryParse(fileUrl)?.pathSegments.last ?? 'файл'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                                child: InkWell(
                                  onTap: () {
                                    if (hasFile) {
                                      _downloadAndOpenFile(
                                        fileUrl,
                                        displayFileName,
                                      );
                                    } else if (hasText) {
                                      _copyMessage(text);
                                    }
                                  },

                                  onLongPress: hasText
                                      ? () => _showMessageContextMenu(text)
                                      : null,

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
                                        if (hasFile) ...[
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getFileIcon(displayFileName),
                                                size: 22,
                                                color: isMe
                                                    ? colorScheme
                                                          .onPrimaryContainer
                                                    : colorScheme.onSurface,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  displayFileName,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: isMe
                                                            ? colorScheme
                                                                  .onPrimaryContainer
                                                            : colorScheme
                                                                  .onSurface,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else if (hasText)
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
                            hintText: 'Сообщение...',
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
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.small(
                        onPressed: _sendMessage,
                        backgroundColor: colorScheme.primary,
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
