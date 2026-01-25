// lib/widgets/user/chat_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../screens/other/service_chat_screen.dart';

class UserChatTab extends StatefulWidget {
  const UserChatTab({super.key});

  @override
  State<UserChatTab> createState() => _UserChatTabState();
}

class _UserChatTabState extends State<UserChatTab>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _chatPreviews = [];
  List<Map<String, dynamic>> _filteredPreviews = [];

  bool _isLoading = true;
  bool _isSearching = false;

  late TextEditingController _searchController;
  late AnimationController _searchAnimController;
  late Animation<double> _searchFade;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _searchFade = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeInOut,
    );

    _loadChatPreviews();

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
          callback: (_) => _loadChatPreviews(),
        )
        .subscribe();

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase().trim();
      setState(() {
        _filteredPreviews = query.isEmpty
            ? List.from(_chatPreviews)
            : _chatPreviews
                  .where(
                    (chat) =>
                        (chat['specialistName'] as String?)
                            ?.toLowerCase()
                            .contains(query) ??
                        false,
                  )
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadChatPreviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Получаем все сообщения
      final messages = await supabase
          .from('chat_messages')
          .select('id, sender_id, receiver_id, message, timestamp')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('timestamp', ascending: false);

      if (messages.isEmpty) {
        setState(() {
          _chatPreviews = [];
          _filteredPreviews = [];
          _isLoading = false;
        });
        return;
      }

      final Set<String> otherIds = {};
      for (var msg in messages) {
        final other = msg['sender_id'] == currentUserId
            ? msg['receiver_id']
            : msg['sender_id'];
        if (other != null && other != currentUserId) {
          otherIds.add(other as String);
        }
      }

      final profiles = await supabase
          .from('profiles')
          .select('id, display_name, photo_url, specialty')
          .inFilter('id', otherIds.toList());

      final profilesMap = {for (var p in profiles) p['id'] as String: p};

      final Map<String, Map<String, dynamic>> previewsMap = {};

      for (var msg in messages) {
        final isMe = msg['sender_id'] == currentUserId;
        final otherId = isMe ? msg['receiver_id'] : msg['sender_id'];
        if (otherId == null || otherId == currentUserId) continue;

        final profile = profilesMap[otherId] ?? {};

        if (!previewsMap.containsKey(otherId)) {
          previewsMap[otherId] = {
            'specialistId': otherId,
            'specialistName': profile['display_name'] as String? ?? 'Мастер',
            'specialistPhoto': profile['photo_url'] as String?,
            'specialty': profile['specialty'] as String? ?? '',
            'lastMessage': msg['message'] as String? ?? '(нет текста)',
            'timestamp': msg['timestamp'],
            'isOnline': false,
          };
        }

        final preview = previewsMap[otherId]!;
        final msgTime =
            DateTime.tryParse(msg['timestamp'] as String? ?? '') ??
            DateTime.now();

        if (msgTime.isAfter(
          DateTime.tryParse(preview['timestamp'] as String? ?? '2000-01-01') ??
              DateTime(2000),
        )) {
          preview['lastMessage'] = msg['message'] as String? ?? '';
          preview['timestamp'] = msg['timestamp'];
        }
      }

      final list = previewsMap.values.toList()
        ..sort((a, b) {
          final ta =
              DateTime.tryParse(a['timestamp'] as String? ?? '') ??
              DateTime(2000);
          final tb =
              DateTime.tryParse(b['timestamp'] as String? ?? '') ??
              DateTime(2000);
          return tb.compareTo(ta);
        });

      if (mounted) {
        setState(() {
          _chatPreviews = list;
          _filteredPreviews = List.from(list);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка чатов: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      if (date.isAfter(now.subtract(const Duration(days: 1)))) {
        return DateFormat('HH:mm').format(date);
      } else if (date.year == now.year) {
        return DateFormat('d MMM').format(date);
      } else {
        return DateFormat('d.MM.yy').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: _isSearching
            ? FadeTransition(
                opacity: _searchFade,
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Поиск по имени...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                  ),
                ),
              )
            : Text('Чаты', style: TextStyle(color: colorScheme.onSurface),),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _isSearching
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _filteredPreviews = List.from(_chatPreviews);
                      });
                      _searchAnimController.reverse();
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      setState(() => _isSearching = true);
                      _searchAnimController.forward();
                    },
                  ),
          ),
        ],
        // elevation: 0,
        // scrolledUnderElevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _loadChatPreviews,
        color: colorScheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredPreviews.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 88,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isSearching ? 'Ничего не найдено' : 'Нет активных чатов',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSearching
                          ? 'Попробуйте другое имя'
                          : 'Начните общение с мастером',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredPreviews.length,
                itemBuilder: (context, index) {
                  final chat = _filteredPreviews[index];
                  final time = _formatTimestamp(chat['timestamp'] as String?);
                  final name = chat['specialistName'] as String? ?? 'Мастер';
                  final photo = chat['specialistPhoto'] as String?;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surfaceContainerLow,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundImage: photo != null
                            ? NetworkImage(photo)
                            : null,
                        child: photo == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        chat['lastMessage'] as String? ?? 'Начните общение',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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
                                'specialty': chat['specialty'],
                              },
                            ),
                          ),
                        ).then((_) => _loadChatPreviews());
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
