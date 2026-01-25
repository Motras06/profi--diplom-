// lib/screens/other/my_orders_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../screens/other/order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myOrders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  String? _filterStatus; // null = все
  DateTime? _filterDateFrom;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _loadMyOrders();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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

      query = query.eq('user_id', userId);

      if (_filterStatus != null && _filterStatus != 'all') {
        query = query.eq('status', _filterStatus!);
      }

      if (_filterDateFrom != null) {
        final dateStr = _filterDateFrom!.toUtc().toIso8601String();
        query = query.gte('created_at', dateStr);
      }

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

      if (!loadMore && mounted) {
        _animController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Ошибка загрузки заказов: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить заказы: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String? status, ColorScheme colorScheme) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'accepted':
        return colorScheme.secondary; // accent зелёный
      case 'in_progress':
        return colorScheme.primary; // аквамарин
      case 'completed':
        return Colors.tealAccent.shade700;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending': return Icons.hourglass_bottom_rounded;
      case 'accepted': return Icons.check_circle_rounded;
      case 'in_progress': return Icons.autorenew_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Неизвестно';
    final map = {
      'pending': 'Ожидает',
      'accepted': 'Принят',
      'in_progress': 'В работе',
      'completed': 'Завершён',
      'cancelled': 'Отменён',
    };
    return map[status] ?? status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  Future<void> _generateOrderPdf(Map<String, dynamic> order) async {
    final pdf = PdfDocument();
    final page = pdf.pages.add();

    final service = order['services'] as Map? ?? {};
    final specialist = order['profiles'] as Map? ?? {};
    final details = order['contract_details'] as Map? ?? {};

    final date = DateTime.parse(order['created_at'] as String).toLocal();
    final formattedDate = DateFormat('dd MMM yyyy HH:mm', 'ru').format(date);

    // Заголовок
    page.graphics.drawString(
      'Детали заказа #${order['id']}',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: const Rect.fromLTWH(0, 0, 500, 50),
    );

    // Информация о специалисте
    page.graphics.drawString(
      'Исполнитель: ${specialist['display_name'] ?? 'Не указан'}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 60, 500, 20),
    );

    // Услуга и цена
    page.graphics.drawString(
      'Услуга: ${service['name'] ?? 'Не указана'}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 90, 500, 20),
    );

    // Цена
    page.graphics.drawString(
      'Цена: ${service['price'] ?? 'По договорённости'} BYN',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 110, 500, 20),
    );

    // Дата создания
    page.graphics.drawString(
      'Дата создания: $formattedDate',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 140, 500, 20),
    );

    // Контракт детали
    page.graphics.drawString(
      'Детали контракта:',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      bounds: const Rect.fromLTWH(0, 170, 500, 30),
    );

    double y = 200;
    details.forEach((key, value) {
      page.graphics.drawString(
        '${key.toUpperCase()}: $value',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, y, 500, 20),
      );
      y += 20;
    });

    // Статус
    page.graphics.drawString(
      'Статус: ${_formatStatus(order['status'])}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(0, y + 20, 500, 20),
    );

    // Сохранение PDF
    final bytes = await pdf.save();
    pdf.dispose();

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/order_${order['id']}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    final openResult = await OpenFilex.open(filePath);
    if (openResult.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка открытия PDF: ${openResult.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Фильтр',
            onSelected: (value) {
              setState(() {
                _filterStatus = value == 'all' ? null : value;
              });
              _loadMyOrders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Все заказы')),
              const PopupMenuItem(value: 'pending', child: Text('Ожидает')),
              const PopupMenuItem(value: 'accepted', child: Text('Принят')),
              const PopupMenuItem(value: 'in_progress', child: Text('В работе')),
              const PopupMenuItem(value: 'completed', child: Text('Завершён')),
              const PopupMenuItem(value: 'cancelled', child: Text('Отменён')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => _loadMyOrders(),
        color: colorScheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _myOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 88,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'У вас пока нет заказов',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Создайте первый заказ на главной странице',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Вернуться назад'),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myOrders.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _myOrders.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: _isLoadingMore
                                  ? const Center(child: CircularProgressIndicator())
                                  : OutlinedButton(
                                      onPressed: () => _loadMyOrders(loadMore: true),
                                      child: const Text('Загрузить ещё'),
                                    ),
                            );
                          }

                          final order = _myOrders[index];
                          final service = order['services'] as Map? ?? {};
                          final specialist = order['profiles'] as Map? ?? {};
                          final status = order['status'] as String?;
                          final date = DateTime.parse(order['created_at'] as String).toLocal();
                          final formattedDate = DateFormat('dd MMM yyyy HH:mm', 'ru').format(date);
                          final details = order['contract_details'] as Map? ?? {};

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            color: colorScheme.surfaceContainerLowest,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderDetailScreen(order: order),
                                  ),
                                ).then((_) => _loadMyOrders());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: colorScheme.primaryContainer,
                                          foregroundImage: specialist['photo_url'] != null
                                              ? NetworkImage(specialist['photo_url'])
                                              : null,
                                          child: specialist['photo_url'] == null
                                              ? Text(
                                                  (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                                  style: TextStyle(
                                                    color: colorScheme.onPrimaryContainer,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service['name'] ?? 'Услуга не указана',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                specialist['display_name'] ?? 'Исполнитель',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _generateOrderPdf(order),
                                              child: Icon(
                                                Icons.picture_as_pdf_rounded,
                                                color: colorScheme.primary,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Chip(
                                              label: Text(
                                                _formatStatus(status),
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                              avatar: Icon(
                                                _getStatusIcon(status),
                                                size: 16,
                                                color: _getStatusColor(status, colorScheme),
                                              ),
                                              backgroundColor: _getStatusColor(status, colorScheme).withOpacity(0.12),
                                              side: BorderSide.none,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (details.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Адрес: ${details['address'] ?? 'не указан'}',
                                              style: theme.textTheme.bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Дата: ${details['preferred_date'] ?? '—'} ${details['preferred_time'] ?? ''}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Продолжительность: ${details['duration'] ?? 'не указана'}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      'Создан: $formattedDate',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
      ),
    );
  }
}