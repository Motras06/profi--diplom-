import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);

    try {
      final response = await supabase
          .from('profiles')
          .select('id, role, display_name, created_at, photo_url')
          .order('created_at', ascending: false)
          .limit(150);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return const Center(child: Text('Пользователей пока нет'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final role = user['role'] as String? ?? '—';
          final name = user['display_name'] as String? ?? 'Без имени';

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user['photo_url'] != null
                  ? NetworkImage(user['photo_url'])
                  : null,
              child: user['photo_url'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(name),
            subtitle: Text(
              'ID: ${user['id']}\nРоль: $role • ${user['created_at']?.toString().substring(0, 10) ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: role == 'specialist'
                ? Chip(
                    label: const Text('Мастер', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green[100],
                  )
                : null,
            onTap: () {},
          );
        },
      ),
    );
  }
}
