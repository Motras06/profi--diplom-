// lib/screens/admin/tabs/chat_monitor_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class ChatMonitorTab extends StatefulWidget {
  const ChatMonitorTab({super.key});

  @override
  State<ChatMonitorTab> createState() => _ChatMonitorTabState();
}

class _ChatMonitorTabState extends State<ChatMonitorTab> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentMessages();
  }

  Future<void> _loadRecentMessages() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('chat_messages')
          .select('''
            id, sender_id, receiver_id, message, timestamp, read,
            profiles!sender_id (display_name as sender_name),
            profiles!receiver_id (display_name as receiver_name)
          ''')
          .order('timestamp', ascending: false)
          .limit(80);

      setState(() {
        _messages = List.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_messages.isEmpty)
      return const Center(child: Text('Сообщений не найдено'));

    return RefreshIndicator(
      onRefresh: _loadRecentMessages,
      child: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, i) {
          final msg = _messages[i];
          final from =
              msg['sender_name'] ?? msg['sender_id'].toString().substring(0, 8);
          final to =
              msg['receiver_name'] ??
              msg['receiver_id'].toString().substring(0, 8);

          return ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(
              msg['message'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$from → $to • ${msg['timestamp']?.substring(0, 16) ?? ''}',
            ),
            dense: true,
            onTap: () {},
          );
        },
      ),
    );
  }
}
