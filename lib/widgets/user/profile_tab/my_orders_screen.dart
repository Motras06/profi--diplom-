import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
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

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myOrders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  String? _filterStatus;
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
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

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
      var query = supabase.from('orders').select('''
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
        return colorScheme.secondary;
      case 'in_progress':
        return colorScheme.primary;
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
      case 'pending':
        return Icons.hourglass_bottom_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'in_progress':
        return Icons.autorenew_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
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
    return map[status] ??
        status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  Future<void> _generateOrderPdf(Map<String, dynamic> order) async {
    
    try {
      await initializeDateFormatting('ru');
      final pdf = PdfDocument();

      // Правильно задаём размер страницы для всего документа
      pdf.pageSettings.size = PdfPageSize.a4;
      pdf.pageSettings.margins.all = 40;
      pdf.pageSettings.orientation = PdfPageOrientation.portrait;

      // Шрифт DejaVuSans
      final fontData = await DefaultAssetBundle.of(
        context,
      ).load('assets/fonts/DejaVuSans.ttf');
      final ttf = PdfTrueTypeFont(fontData.buffer.asUint8List(), 12);
      final boldFont = PdfTrueTypeFont(
        fontData.buffer.asUint8List(),
        14,
        style: PdfFontStyle.bold,
      );

      final page = pdf.pages.add();
      final pageGraphics = page.graphics;

      final service = order['services'] as Map? ?? {};
      final specialist = order['profiles'] as Map? ?? {};
      final details = order['contract_details'] as Map? ?? {};

      final date = DateTime.parse(order['created_at'] as String).toLocal();
      final formattedDate = DateFormat(
        'dd MMMM yyyy, HH:mm',
        'ru',
      ).format(date);

      double y = page.getClientSize().height - 80; // правильный отступ сверху

      // Заголовок
      pageGraphics.drawString(
        'Заказ №${order['id']}',
        boldFont,
        brush: PdfSolidBrush(PdfColor(0, 102, 204)),
        bounds: Rect.fromLTWH(0, y, page.getClientSize().width, 40),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y -= 60;

      // Дата создания
      pageGraphics.drawString(
        'Создан: $formattedDate',
        ttf,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(40, y, page.getClientSize().width - 80, 25),
      );
      y -= 45;

      // Статус
      final statusText = _formatStatus(order['status']);
      final statusColor = _getStatusColor(
        order['status'],
        Theme.of(context).colorScheme,
      );
      final statusBrush = PdfSolidBrush(
        PdfColor(
          statusColor.red * 255,
          statusColor.green * 255,
          statusColor.blue * 255,
        ),
      );

      pageGraphics.drawString(
        'Статус: $statusText',
        boldFont,
        brush: statusBrush,
        bounds: Rect.fromLTWH(40, y, page.getClientSize().width - 80, 30),
      );
      y -= 50;

      // Разделитель
      pageGraphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(220, 220, 220)),
        bounds: Rect.fromLTWH(40, y, page.getClientSize().width - 80, 1),
      );
      y -= 40;

      // Основная информация
      _drawLabelValue(
        pageGraphics,
        ttf,
        boldFont,
        'Услуга',
        service['name'] ?? '—',
        40,
        y,
        page.getClientSize().width,
      );
      y -= 35;
      _drawLabelValue(
        pageGraphics,
        ttf,
        boldFont,
        'Исполнитель',
        specialist['display_name'] ?? '—',
        40,
        y,
        page.getClientSize().width,
      );
      y -= 35;
      _drawLabelValue(
        pageGraphics,
        ttf,
        boldFont,
        'Цена',
        service['price'] != null
            ? '${service['price']} BYN'
            : 'По договорённости',
        40,
        y,
        page.getClientSize().width,
      );
      y -= 50;

      // Детали заказа
      if (details.isNotEmpty) {
        pageGraphics.drawString(
          'Детали заказа',
          boldFont,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(40, y, page.getClientSize().width - 80, 30),
        );
        y -= 40;

        details.forEach((key, value) {
          final niceKey = key
              .toString()
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' ');

          _drawLabelValue(
            pageGraphics,
            ttf,
            boldFont,
            niceKey,
            value?.toString() ?? '—',
            40,
            y,
            page.getClientSize().width,
          );
          y -= 35;
        });
      }

      // Нижний колонтитул
      pageGraphics.drawString(
        'Сгенерировано в приложении ProWirkSearch • ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
        ttf,
        brush: PdfSolidBrush(PdfColor(140, 140, 140)),
        bounds: Rect.fromLTWH(40, 40, page.getClientSize().width - 80, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      final bytes = await pdf.save();
      pdf.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/order_${order['id']}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      debugPrint('PDF сохранён: $filePath');

      final result = await OpenFilex.open(
        filePath,
        type: 'application/pdf',
        uti: 'com.adobe.pdf',
      );

      debugPrint(
        'OpenFilex result: ${result.type}, message: ${result.message}',
      );

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Не удалось открыть PDF: ${result.message ?? "Нет приложения для просмотра PDF"}',
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('PDF generation/open error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при работе с PDF: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  void _drawLabelValue(
    PdfGraphics graphics,
    PdfFont regularFont,
    PdfFont boldFont,
    String label,
    String value,
    double x,
    double y,
    double pageWidth, // ← добавляем параметр ширины страницы
  ) {
    graphics.drawString(
      '$label:',
      boldFont,
      brush: PdfSolidBrush(PdfColor(50, 50, 50)),
      bounds: Rect.fromLTWH(x, y, 200, 30),
    );

    graphics.drawString(
      value,
      regularFont,
      brush: PdfSolidBrush(PdfColor(30, 30, 30)),
      bounds: Rect.fromLTWH(
        x + 210,
        y,
        pageWidth - x - 250,
        120,
      ), // высота увеличена под переносы
      format: PdfStringFormat(
        lineSpacing: 4,
        wordWrap: PdfWordWrapType.word, // ← правильное имя
      ),
    );
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
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('В работе'),
              ),
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
                                  onPressed: () =>
                                      _loadMyOrders(loadMore: true),
                                  child: const Text('Загрузить ещё'),
                                ),
                        );
                      }

                      final order = _myOrders[index];
                      final details = order['contract_details'] as Map? ?? {};

                      final status = order['status'] as String? ?? 'unknown';
                      final createdAtRaw = order['created_at'] as String?;
                      String formattedDate = '—';
                      if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
                        try {
                          final date = DateTime.parse(createdAtRaw).toLocal();
                          formattedDate = DateFormat(
                            'dd MMM yyyy HH:mm',
                            'ru',
                          ).format(date);
                        } catch (_) {}
                      }

                      final serviceName =
                          (order['services'] as Map? ?? {})['name']
                              as String? ??
                          'Услуга не указана';
                      final specialistName =
                          (order['profiles'] as Map? ?? {})['display_name']
                              as String? ??
                          'Мастер';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shadowColor: Colors.black.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
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
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      child: Text(
                                        specialistName.isNotEmpty
                                            ? specialistName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            serviceName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            specialistName,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _generateOrderPdf(order),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        size: 32,
                                      ),
                                      tooltip: 'Открыть PDF заказа',
                                      color: colorScheme.primary,
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary
                                            .withOpacity(0.1),
                                        padding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        _formatStatus(status),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      avatar: Icon(
                                        _getStatusIcon(status),
                                        size: 16,
                                        color: _getStatusColor(
                                          status,
                                          colorScheme,
                                        ),
                                      ),
                                      backgroundColor: _getStatusColor(
                                        status,
                                        colorScheme,
                                      ).withOpacity(0.12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (details.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
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
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
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
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
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
