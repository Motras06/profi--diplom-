import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('services')
          .select('*, profiles!inner(display_name)')
          .order('created_at', ascending: false);

      setState(() {
        _services = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteService(int id) async {
    try {
      await supabase.from('services').delete().eq('id', id);
      await supabase.from('service_photos').delete().eq('service_id', id);
      _loadServices();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Услуга удалена')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadServices,
      child: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, i) {
          final s = _services[i];
          final specialistName = s['profiles']?['display_name'] ?? '—';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ExpansionTile(
              leading: const Icon(Icons.work_outline),
              title: Text(s['name'] ?? 'Без названия'),
              subtitle: Text('$specialistName • ${s['price'] ?? '?'} ₽'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['description'] ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.delete_forever,
                              size: 18,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Удалить услугу?'),
                                  content: Text(
                                    'Будет удалена услуга «${s['name']}»',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteService(s['id']);
                                      },
                                      child: const Text(
                                        'Удалить',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
