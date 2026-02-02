import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../screens/other/chat_specialist.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with SingleTickerProviderStateMixin {
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

    _loadChats();

    supabase
        .channel('specialist-chats:${supabase.auth.currentUser?.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: supabase.auth.currentUser?.id,
          ),
          callback: (_) => _loadChats(),
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
                        (chat['clientName'] as String?)?.toLowerCase().contains(
                          query,
                        ) ??
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

  Future<void> _loadChats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final specialistId = supabase.auth.currentUser?.id;
    if (specialistId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final blacklistRes = await supabase
          .from('blacklists')
          .select('blacklisted_user_id')
          .eq('specialist_id', specialistId);

      final blacklistedIds = blacklistRes
          .map((e) => e['blacklisted_user_id'] as String)
          .toSet();

      final messages = await supabase
          .from('chat_messages')
          .select('''
            id, sender_id, receiver_id, message, timestamp, read,
            profiles!sender_id (display_name, photo_url)
          ''')
          .eq('receiver_id', specialistId)
          .order('timestamp', ascending: false);

      final Map<String, Map<String, dynamic>> chatMap = {};

      for (final msg in messages) {
        final senderId = msg['sender_id'] as String?;
        if (senderId == null || blacklistedIds.contains(senderId)) continue;

        final senderProfile = msg['profiles'] as Map<String, dynamic>? ?? {};

        DateTime? msgTime;
        try {
          msgTime = DateTime.tryParse(msg['timestamp'] as String? ?? '');
        } catch (_) {}

        if (!chatMap.containsKey(senderId)) {
          chatMap[senderId] = {
            'clientId': senderId,
            'clientName': senderProfile['display_name'] as String? ?? 'Клиент',
            'clientPhoto': senderProfile['photo_url'] as String?,
            'lastMessage': msg['message'] as String? ?? '(нет текста)',
            'timestamp': msg['timestamp'],
            'lastTimestamp': msgTime ?? DateTime(2000),
            'isOnline': false,
          };
        }

        final existing = chatMap[senderId]!;
        if (msgTime != null &&
            msgTime.isAfter(existing['lastTimestamp'] as DateTime)) {
          existing['lastMessage'] = msg['message'] as String? ?? '';
          existing['timestamp'] = msg['timestamp'];
          existing['lastTimestamp'] = msgTime;
        }
      }

      final list = chatMap.values.toList()
        ..sort(
          (a, b) => (b['lastTimestamp'] as DateTime).compareTo(
            a['lastTimestamp'] as DateTime,
          ),
        );

      if (mounted) {
        setState(() {
          _chatPreviews = list;
          _filteredPreviews = List.from(list);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки чатов специалиста: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '—';
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
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                    hintText: 'Поиск по имени клиента...',
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: InputBorder.none,
                  ),
                ),
              )
            : Text('Чаты', style: TextStyle(color: colorScheme.onSurface)),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _loadChats,
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
                          : 'Когда клиенты напишут — чаты появятся здесь',
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
                  final name = chat['clientName'] as String? ?? 'Клиент';
                  final photo = chat['clientPhoto'] as String?;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    elevation: 16,
                    shadowColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surfaceContainerLowest,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            builder: (context) => SpecialistChatScreen(
                              clientId: chat['clientId'] as String,
                              clientName: name,
                              clientPhoto: photo,
                              isOnline: chat['isOnline'] as bool? ?? false,
                            ),
                          ),
                        ).then((_) => _loadChats());
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
