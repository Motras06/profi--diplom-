// lib/screens/specialist/orders_tab.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

enum OrdersViewMode { verification, accepted, completed, blacklist }

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
  List<Map<String, dynamic>> _acceptedOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _blacklistedUsers = [];

  bool _isLoading = true;
  String? _specialistId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentMode = OrdersViewMode.values[_tabController.index];
      });
    });

    _specialistId = supabase.auth.currentUser?.id;
    if (_specialistId != null) {
      _loadData();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не авторизован')),
          );
        }
      });
    }
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
      final results = await Future.wait([
        // 0: Верификация (pending)
        supabase
            .from('orders')
            .select('''
              id, created_at, user_id, service_id, status,
              profiles!user_id (display_name, photo_url),
              services (name, price)
            ''')
            .eq('specialist_id', _specialistId!)
            .eq('status', 'pending')
            .order('created_at', ascending: false),

        // 1: Одобренные (accepted)
        supabase
            .from('orders')
            .select('''
              id, created_at, user_id, service_id, status,
              profiles!user_id (display_name, photo_url),
              services (name, price)
            ''')
            .eq('specialist_id', _specialistId!)
            .eq('status', 'accepted')
            .order('created_at', ascending: false),

        // 2: Выполненные (completed)
        supabase
            .from('orders')
            .select('''
              id, created_at, user_id, service_id, status,
              profiles!user_id (display_name, photo_url),
              services (name, price)
            ''')
            .eq('specialist_id', _specialistId!)
            .eq('status', 'completed')
            .order('created_at', ascending: false),

        // 3: Чёрный список
        supabase
            .from('blacklists')
            .select('''
              blacklisted_user_id, reason, created_at,
              profiles!blacklisted_user_id (display_name, photo_url)
            ''')
            .eq('specialist_id', _specialistId!)
            .order('created_at', ascending: false),
      ]);

      if (!mounted) return;

      setState(() {
        _pendingOrders   = List<Map<String, dynamic>>.from(results[0]);
        _acceptedOrders  = List<Map<String, dynamic>>.from(results[1]);
        _completedOrders = List<Map<String, dynamic>>.from(results[2]);
        _blacklistedUsers = List<Map<String, dynamic>>.from(results[3]);
      });
    } catch (e, stack) {
      debugPrint('Ошибка загрузки заказов: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Действия ──────────────────────────────────────────────────────────────

  Future<void> _acceptOrder(int orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'accepted'})
          .eq('id', orderId)
          .eq('specialist_id', _specialistId!);

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ принят')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить заказ'),
        content: const Text('Заказ будет удалён. Продолжить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase
          .from('orders')
          .delete()
          .eq('id', orderId)
          .eq('specialist_id', _specialistId!);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ отклонён и удалён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeOrder(int orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', orderId)
          .eq('specialist_id', _specialistId!);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ завершён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFromBlacklist(String blacklistedUserId) async {
    try {
      await supabase
          .from('blacklists')
          .delete()
          .eq('specialist_id', _specialistId!)
          .eq('blacklisted_user_id', blacklistedUserId);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Клиент удалён из чёрного списка')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Карточки ──────────────────────────────────────────────────────────────

  Widget _buildOrderCard(Map<String, dynamic> order, {
    required String mode,
  }) {
    final user = order['profiles'] as Map<String, dynamic>? ?? {};
    final service = order['services'] as Map<String, dynamic>? ?? {};

    final displayName = user['display_name'] as String? ?? 'Клиент';
    final photoUrl = user['photo_url'] as String?;
    final serviceName = service['name'] as String? ?? 'Услуга';
    final price = service['price'] as num?;

    final createdAt = DateTime.parse(order['created_at'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null ? Text(displayName[0].toUpperCase()) : null,
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName),
            if (price != null) Text('Цена: $price ₽'),
            Text(
              'Создан: ${createdAt.day}.${createdAt.month}.${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: mode == 'verification'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                    onPressed: () => _acceptOrder(order['id'] as int),
                    tooltip: 'Принять',
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    onPressed: () => _rejectOrder(order['id'] as int),
                    tooltip: 'Отклонить',
                  ),
                ],
              )
            : mode == 'accepted'
                ? IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.blue),
                    onPressed: () => _completeOrder(order['id'] as int),
                    tooltip: 'Завершить',
                  )
                : const Icon(Icons.check_circle, color: Colors.green, size: 32),
      ),
    );
  }

  Widget _buildBlacklistCard(Map<String, dynamic> entry) {
    final user = entry['profiles'] as Map<String, dynamic>? ?? {};
    final displayName = user['display_name'] as String? ?? 'Клиент';
    final photoUrl = user['photo_url'] as String?;
    final reason = entry['reason'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null ? Text(displayName[0].toUpperCase()) : null,
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: reason != null
            ? Text('Причина: $reason', style: TextStyle(color: Colors.grey[700]))
            : const Text('Причина не указана'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeFromBlacklist(entry['blacklisted_user_id'] as String),
          tooltip: 'Удалить из чёрного списка',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    List<Widget> currentList = [];
    String emptyText = '';

    switch (_currentMode) {
      case OrdersViewMode.verification:
        currentList = _pendingOrders.map((o) => _buildOrderCard(o, mode: 'verification')).toList();
        emptyText = 'Нет заказов на верификацию';
        break;
      case OrdersViewMode.accepted:
        currentList = _acceptedOrders.map((o) => _buildOrderCard(o, mode: 'accepted')).toList();
        emptyText = 'Нет одобренных заказов';
        break;
      case OrdersViewMode.completed:
        currentList = _completedOrders.map((o) => _buildOrderCard(o, mode: 'completed')).toList();
        emptyText = 'Нет выполненных заказов';
        break;
      case OrdersViewMode.blacklist:
        currentList = _blacklistedUsers.map(_buildBlacklistCard).toList();
        emptyText = 'Чёрный список пуст';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Верификация'),
            Tab(text: 'Одобренные'),
            Tab(text: 'Выполненные'),
            Tab(text: 'Чёрный список'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: currentList.isEmpty
                  ? Center(
                      child: Text(
                        emptyText,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: currentList,
                    ),
            ),
    );
  }
}