// lib/screens/admin/tabs/blacklist_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class BlacklistTab extends StatefulWidget {
  const BlacklistTab({super.key});

  @override
  State<BlacklistTab> createState() => _BlacklistTabState();
}

class _BlacklistTabState extends State<BlacklistTab> {
  List<Map<String, dynamic>> _blacklisted = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBlacklist();
  }

  Future<void> _loadBlacklist() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('blacklists')
          .select('''
            id, reason, created_at,
            profiles!specialist_id (display_name as specialist_name),
            profiles!blacklisted_user_id (display_name as user_name)
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _blacklisted = List.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _removeFromBlacklist(int id) async {
    try {
      await supabase.from('blacklists').delete().eq('id', id);
      _loadBlacklist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь разблокирован')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.person_add_disabled),
            label: const Text('Добавить в чёрный список'),
            onPressed: () {
              // → диалог / экран поиска пользователя + выбор специалиста + причина
            },
          ),
        ),
        Expanded(
          child: _blacklisted.isEmpty
              ? const Center(child: Text('Чёрный список пуст'))
              : ListView.builder(
                  itemCount: _blacklisted.length,
                  itemBuilder: (context, i) {
                    final entry = _blacklisted[i];
                    return ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(entry['user_name'] ?? '—'),
                      subtitle: Text(
                        'Заблокирован мастером: ${entry['specialist_name'] ?? '?'}\n'
                        '${entry['reason'] ?? 'Без причины'} • ${entry['created_at']?.substring(0, 10) ?? ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.green,
                        onPressed: () => _removeFromBlacklist(entry['id']),
                        tooltip: 'Разблокировать',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}