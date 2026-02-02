import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class SpecialistsTab extends StatefulWidget {
  const SpecialistsTab({super.key});

  @override
  State<SpecialistsTab> createState() => _SpecialistsTabState();
}

class _SpecialistsTabState extends State<SpecialistsTab> {
  List<Map<String, dynamic>> _specialists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecialists();
  }

  Future<void> _loadSpecialists() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('profiles')
          .select('id, display_name, specialty, about, photo_url, created_at')
          .eq('role', 'specialist')
          .order('created_at', ascending: false);

      setState(() {
        _specialists = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _blockSpecialist(String id) async {
    try {
      await supabase.from('profiles').update({'role': 'blocked'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Специалист заблокирован')),
        );
        _loadSpecialists();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось заблокировать: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_specialists.isEmpty) {
      return const Center(child: Text('Активных специалистов пока нет'));
    }

    return RefreshIndicator(
      onRefresh: _loadSpecialists,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _specialists.length,
        itemBuilder: (context, i) {
          final sp = _specialists[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: sp['photo_url'] != null
                    ? NetworkImage(sp['photo_url'])
                    : null,
                child: sp['photo_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(sp['display_name'] ?? 'Без имени'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sp['specialty'] ?? '—',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  Text(
                    sp['about']?.substring(
                          0,
                          sp['about']?.length > 60 ? 60 : null,
                        ) ??
                        '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                onPressed: () => _blockSpecialist(sp['id']),
                tooltip: 'Заблокировать',
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
