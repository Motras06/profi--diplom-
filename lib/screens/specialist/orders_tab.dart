import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

enum OrdersViewMode { verification, accepted, completed, blacklist }

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _acceptedOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];
  List<Map<String, dynamic>> _blacklistedUsers = [];

  bool _isLoading = true;
  String? _specialistId;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _specialistId = supabase.auth.currentUser?.id;
    if (_specialistId != null) {
      _loadData();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
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

        supabase
            .from('blacklists')
            .select('''
              blacklisted_user_id, reason, created_at,
              profiles!blacklisted_user_id (display_name, photo_url)
            ''')
            .eq('specialist_id', _specialistId!)
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _pendingOrders = List<Map<String, dynamic>>.from(results[0]);
          _acceptedOrders = List<Map<String, dynamic>>.from(results[1]);
          _completedOrders = List<Map<String, dynamic>>.from(results[2]);
          _blacklistedUsers = List<Map<String, dynamic>>.from(results[3]);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки заказов: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'accepted'})
          .eq('id', orderId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Заказ принят')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _rejectOrder(int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отклонить заказ?'),
        content: const Text(
          'Заказ будет удалён без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('orders').delete().eq('id', orderId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заказ отклонён и удалён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _completeOrder(int orderId) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'completed'})
          .eq('id', orderId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Заказ завершён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _removeFromBlacklist(String blacklistedUserId) async {
    try {
      await supabase
          .from('blacklists')
          .delete()
          .eq('blacklisted_user_id', blacklistedUserId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Клиент удалён из чёрного списка')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order, OrdersViewMode mode) {
    final user = order['profiles'] as Map<String, dynamic>? ?? {};
    final service = order['services'] as Map<String, dynamic>? ?? {};

    final displayName = user['display_name'] as String? ?? 'Клиент';
    final photoUrl = user['photo_url'] as String?;
    final serviceName = service['name'] as String? ?? 'Услуга';
    final price = service['price'] as num?;
    final createdAt = DateTime.parse(order['created_at'] as String);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName),
            if (price != null) Text('Цена: $price ₽'),
            Text(
              'Создан: ${createdAt.day}.${createdAt.month}.${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: mode == OrdersViewMode.verification
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _acceptOrder(order['id'] as int),
                    tooltip: 'Принять',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _rejectOrder(order['id'] as int),
                    tooltip: 'Отклонить',
                  ),
                ],
              )
            : mode == OrdersViewMode.accepted
            ? IconButton(
                icon: Icon(
                  Icons.done_all_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _completeOrder(order['id'] as int),
                tooltip: 'Завершить',
              )
            : Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
      ),
    );
  }

  Widget _buildBlacklistCard(Map<String, dynamic> entry) {
    final user = entry['profiles'] as Map<String, dynamic>? ?? {};
    final displayName = user['display_name'] as String? ?? 'Клиент';
    final photoUrl = user['photo_url'] as String?;
    final reason = entry['reason'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          displayName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          reason != null ? 'Причина: $reason' : 'Причина не указана',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.remove_circle_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () =>
              _removeFromBlacklist(entry['blacklisted_user_id'] as String),
          tooltip: 'Удалить из чёрного списка',
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 88,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 32),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Когда появятся заказы — они отобразятся здесь',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final navBarColor = ElevationOverlay.applySurfaceTint(
      colorScheme.surface,
      colorScheme.surfaceTint,
      3,
    );

    List<Widget> currentList = [];
    String emptyText = '';

    switch (_selectedIndex) {
      case 0:
        currentList = _pendingOrders
            .map((o) => _buildOrderCard(o, OrdersViewMode.verification))
            .toList();
        emptyText = 'Нет заказов на верификацию';
        break;
      case 1:
        currentList = _acceptedOrders
            .map((o) => _buildOrderCard(o, OrdersViewMode.accepted))
            .toList();
        emptyText = 'Нет одобренных заказов';
        break;
      case 2:
        currentList = _completedOrders
            .map((o) => _buildOrderCard(o, OrdersViewMode.completed))
            .toList();
        emptyText = 'Нет выполненных заказов';
        break;
      case 3:
        currentList = _blacklistedUsers.map(_buildBlacklistCard).toList();
        emptyText = 'Чёрный список пуст';
        break;
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBody: true,
      appBar: AppBar(
        title: Text('Заказы', style: TextStyle(color: colorScheme.onSurface)),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : currentList.isEmpty
            ? _buildEmptyState(emptyText)
            : RefreshIndicator.adaptive(
                onRefresh: _loadData,
                color: colorScheme.primary,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: currentList,
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.24),
                  blurRadius: 32,
                  spreadRadius: 8,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              elevation: 0,
              color: navBarColor,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: NavigationBar(
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                selectedIndex: _selectedIndex,
                backgroundColor: Colors.transparent,
                indicatorColor: colorScheme.primary.withOpacity(0.22),
                height: 76,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.pending_outlined),
                    selectedIcon: Icon(Icons.pending_rounded),
                    label: 'Верификация',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.check_circle_outline_rounded),
                    selectedIcon: Icon(Icons.check_circle_rounded),
                    label: 'Одобренные',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.done_all_outlined),
                    selectedIcon: Icon(Icons.done_all_rounded),
                    label: 'Выполненные',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.block_outlined),
                    selectedIcon: Icon(Icons.block_rounded),
                    label: 'Чёрный список',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
