// lib/screens/specialist/orders_tab.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

enum OrdersViewMode { verification, completed, blacklist }

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final TabController _tabController;

  OrdersViewMode _currentMode = OrdersViewMode.verification;

  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _blacklistedUsers = [];

  bool _isLoading = true;

  String? _specialistId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentMode = OrdersViewMode.values[_tabController.index];
      });
    });

    _specialistId = supabase.auth.currentUser?.id;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (_specialistId == null) throw 'Не авторизован';

      final results = await Future.wait([
        supabase
            .from('orders')
            .select('id, created_at, user_id, service_id, status, profiles!user_id(display_name, photo_url), services(name, price)')
            .eq('specialist_id', _specialistId!)
            .eq('status', 'pending')
            .order('created_at', ascending: false),

        supabase
            .from('orders')
            .select('id, created_at, user_id, service_id, status, profiles!user_id(display_name, photo_url), services(name, price)')
            .eq('specialist_id', _specialistId!)
            .eq('status', 'completed')
            .order('created_at', ascending: false),

        supabase
            .from('blacklists')
            .select('blacklisted_user_id, reason, profiles!blacklisted_user_id(display_name, photo_url)')
            .eq('specialist_id', _specialistId!),
      ]);

      if (!mounted) return;

      setState(() {
        _pendingOrders = List<Map<String, dynamic>>.from(results[0] as List);
        _completedOrders = List<Map<String, dynamic>>.from(results[1] as List);
        _blacklistedUsers = List<Map<String, dynamic>>.from(results[2] as List);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Затычки — добавляются в конец реальных списков
  List<Map<String, dynamic>> get _displayPending =>
      [..._pendingOrders, ..._fakePendingOrders()];

  List<Map<String, dynamic>> get _displayCompleted =>
      [..._completedOrders, ..._fakeCompletedOrders()];

  List<Map<String, dynamic>> get _displayBlacklisted =>
      [..._blacklistedUsers, ..._fakeBlacklistedUsers()];

  List<Map<String, dynamic>> _fakePendingOrders() => [
        {
          'id': -1, // Отрицательный ID, чтобы не конфликтовать
          'profiles': {'display_name': 'Алексей Иванов', 'photo_url': null},
          'services': {'name': 'Ремонт ванной комнаты', 'price': 25000},
        },
        {
          'id': -2,
          'profiles': {'display_name': 'Мария Петрова', 'photo_url': null},
          'services': {'name': 'Замена электропроводки', 'price': null},
        },
        {
          'id': -3,
          'profiles': {'display_name': 'Дмитрий Сидоров', 'photo_url': null},
          'services': {'name': 'Установка кондиционера', 'price': 18000},
        },
      ];

  List<Map<String, dynamic>> _fakeCompletedOrders() => [
        {
          'id': -101,
          'profiles': {'display_name': 'Ольга Кузнецова', 'photo_url': null},
          'services': {'name': 'Покраска стен', 'price': 12000},
        },
        {
          'id': -102,
          'profiles': {'display_name': 'Сергей Морозов', 'photo_url': null},
          'services': {'name': 'Сборка кухонного гарнитура', 'price': 8000},
        },
        {
          'id': -103,
          'profiles': {'display_name': 'Екатерина Волкова', 'photo_url': null},
          'services': {'name': 'Ремонт сантехники', 'price': 4500},
        },
      ];

  List<Map<String, dynamic>> _fakeBlacklistedUsers() => [
        {
          'blacklisted_user_id': 'fake-bad-1',
          'reason': 'Не вышел на связь после одобрения',
          'profiles': {'display_name': 'Виктор Зайцев', 'photo_url': null},
        },
        {
          'blacklisted_user_id': 'fake-bad-2',
          'reason': 'Отказался от оплаты',
          'profiles': {'display_name': 'Игорь Козлов', 'photo_url': null},
        },
      ];

  // Кнопки работают как демо
  Future<void> _approveOrder(int orderId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Заказ одобрен (демо-режим)')),
    );
  }

  Future<void> _rejectOrder(int orderId, String userId) async {
    final reasonCtrl = TextEditingController();

    final reject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить заказ'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Причина отклонения (необязательно)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (reject == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ отклонён (демо-режим)')),
      );
      if (reasonCtrl.text.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Клиент добавлен в чёрный список (демо-режим)')),
        );
      }
    }
  }

  Future<void> _removeFromBlacklist(String userId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Клиент удалён из чёрного списка (демо-режим)')),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isPending}) {
    final user = order['profiles'] ?? {'display_name': 'Клиент', 'photo_url': null};
    final service = order['services'] ?? {'name': 'Услуга', 'price': null};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text((user['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?'),
        ),
        title: Text(user['display_name'] ?? 'Неизвестный клиент'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service['name'] ?? 'Услуга удалена'),
            if (service['price'] != null) Text('Цена: ${service['price']} ₽'),
          ],
        ),
        trailing: isPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveOrder(order['id'] ?? 0),
                    tooltip: 'Одобрить',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectOrder(order['id'] ?? 0, user['id'] ?? ''),
                    tooltip: 'Отклонить',
                  ),
                ],
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildBlacklistCard(Map<String, dynamic> entry) {
    final user = entry['profiles'] ?? {'display_name': 'Клиент', 'photo_url': null};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text((user['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?'),
        ),
        title: Text(user['display_name'] ?? 'Неизвестный'),
        subtitle: entry['reason'] != null
            ? Text('Причина: ${entry['reason']}')
            : const Text('Без причины'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeFromBlacklist(entry['blacklisted_user_id'] ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final List<Widget> currentList;

    switch (_currentMode) {
      case OrdersViewMode.verification:
        currentList = _displayPending.map((o) => _buildOrderCard(o, isPending: true)).toList();
        break;
      case OrdersViewMode.completed:
        currentList = _displayCompleted.map((o) => _buildOrderCard(o, isPending: false)).toList();
        break;
      case OrdersViewMode.blacklist:
        currentList = _displayBlacklisted.map(_buildBlacklistCard).toList();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Верификация'),
            Tab(text: 'Выполненные'),
            Tab(text: 'Чёрный список'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: currentList.isEmpty
                    ? [const Center(child: Text('Нет данных'))]
                    : currentList,
              ),
            ),
    );
  }
}