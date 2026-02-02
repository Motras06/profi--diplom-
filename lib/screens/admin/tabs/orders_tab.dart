import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _selectedStatusFilter;

  final Map<String, Color> _statusColors = {
    'new': Colors.blue.shade100,
    'in_progress': Colors.orange.shade100,
    'completed': Colors.green.shade100,
    'cancelled': Colors.red.shade100,
    'disputed': Colors.purple.shade100,
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      var baseQuery = supabase.from('orders').select('''
          id, user_id, specialist_id, service_id, status, created_at, updated_at,
          profiles!user_id (display_name),
          profiles!specialist_id (display_name)
        ''');

      PostgrestFilterBuilder filteredQuery;

      if (_selectedStatusFilter != null && _selectedStatusFilter != 'all') {
        filteredQuery = baseQuery.eq('status', _selectedStatusFilter!);
      } else {
        filteredQuery = baseQuery;
      }

      final finalQuery = filteredQuery.order('created_at', ascending: false);

      final response = await finalQuery;

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButton<String>(
            isExpanded: true,
            hint: const Text('Все статусы'),
            value: _selectedStatusFilter,
            items: const [
              DropdownMenuItem(value: null, child: Text('Все')),
              DropdownMenuItem(value: 'new', child: Text('Новые')),
              DropdownMenuItem(value: 'in_progress', child: Text('В работе')),
              DropdownMenuItem(value: 'completed', child: Text('Завершённые')),
              DropdownMenuItem(value: 'cancelled', child: Text('Отменённые')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatusFilter = value);
              _loadOrders();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _orders.isEmpty
              ? const Center(child: Text('Заказов не найдено'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final status = order['status'] as String? ?? '—';
                      final bgColor =
                          _statusColors[status] ?? Colors.grey.shade100;

                      return Card(
                        color: bgColor,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueGrey.shade200,
                            child: Text('#${order['id']}'),
                          ),
                          title: Text(
                            order['profiles!specialist_id']?['display_name'] ??
                                'Мастер не указан',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Клиент: ${order['profiles!user_id']?['display_name'] ?? '?'}',
                              ),
                              Text(
                                'Статус: $status • ${order['created_at']?.substring(0, 10) ?? ''}',
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (ctx) =>
                                    _OrderActionsBottomSheet(order: order),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _OrderActionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderActionsBottomSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Изменить статус'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Подробная информация'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text(
              'Отменить / заблокировать',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
