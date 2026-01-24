// lib/screens/other/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../screens/other/order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myOrders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  String? _filterStatus; // null = все
  DateTime? _filterDateFrom;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
  }

  Future<void> _loadMyOrders({bool loadMore = false}) async {
  if (loadMore) {
    setState(() => _isLoadingMore = true);
  } else {
    setState(() {
      _isLoading = true;
      _offset = 0;
      _hasMore = true;
    });
  }

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });
    return;
  }

  try {
    var query = supabase
        .from('orders')
        .select('''
          id, status, created_at, contract_details,
          services (id, name),
          profiles!specialist_id (id, display_name, photo_url)
        ''');

    // Фильтры после select — это нормально в supabase_flutter 2.x+
    query = query.eq('user_id', userId);

    if (_filterStatus != null && _filterStatus != 'all') {
      query = query.eq('status', _filterStatus!);
    }

    if (_filterDateFrom != null) {
      final dateStr = _filterDateFrom!.toUtc().toIso8601String();
      query = query.gte('created_at', dateStr);
    }

    // Сортировка + пагинация
    final response = await query
        .order('created_at', ascending: false)
        .range(_offset, _offset + _limit - 1);

    setState(() {
      if (!loadMore) {
        _myOrders = List<Map<String, dynamic>>.from(response);
      } else {
        _myOrders.addAll(List<Map<String, dynamic>>.from(response));
      }
      _offset += _limit;
      _hasMore = response.length == _limit;
      _isLoading = false;
      _isLoadingMore = false;
    });
  } catch (e, stack) {
    debugPrint('Ошибка загрузки заказов: $e\n$stack');
    setState(() {
      _isLoading = false;
      _isLoadingMore = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки заказов: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.purple;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.check_circle_outline;
      case 'in_progress': return Icons.autorenew;
      case 'completed': return Icons.done_all;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Неизвестно';
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'all') _filterStatus = null;
                else _filterStatus = value;
              });
              _loadMyOrders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Все')),
              const PopupMenuItem(value: 'pending', child: Text('Ожидает')),
              const PopupMenuItem(value: 'accepted', child: Text('Принят')),
              const PopupMenuItem(value: 'in_progress', child: Text('В работе')),
              const PopupMenuItem(value: 'completed', child: Text('Завершён')),
              const PopupMenuItem(value: 'cancelled', child: Text('Отменён')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMyOrders(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _myOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 24),
                        const Text('У вас пока нет заказов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Создайте первый заказ на главной странице', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        const SizedBox(height: 40),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Вернуться назад'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _myOrders.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _myOrders.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: _isLoadingMore
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: () => _loadMyOrders(loadMore: true),
                                  child: const Text('Загрузить ещё'),
                                ),
                        );
                      }

                      final order = _myOrders[index];
                      final service = order['services'] ?? {};
                      final specialist = order['profiles'] ?? {};
                      final status = order['status'] as String?;
                      final date = (order['created_at'] as String?)?.split('T')[0] ?? '';
                      final details = order['contract_details'] as Map<String, dynamic>? ?? {};

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailScreen(order: order),
                              ),
                            ).then((_) => _loadMyOrders());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: specialist['photo_url'] != null
                                          ? NetworkImage(specialist['photo_url'])
                                          : null,
                                      child: specialist['photo_url'] == null
                                          ? Text(
                                              (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                              style: const TextStyle(fontSize: 16),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service['name'] ?? 'Услуга',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            specialist['display_name'] ?? 'Мастер',
                                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_getStatusIcon(status), size: 16, color: _getStatusColor(status)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatStatus(status),
                                            style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.w600, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                if (details.isNotEmpty) ...[
                                  Text('Адрес: ${details['address'] ?? 'Не указан'}', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Дата: ${details['preferred_date'] ?? '—'} ${details['preferred_time'] ?? ''}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Продолжительность: ${details['duration'] ?? 'Не указана'}', style: const TextStyle(fontSize: 14)),
                                ],

                                const SizedBox(height: 12),
                                Text('Создан: $date', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}