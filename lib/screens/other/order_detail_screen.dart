// lib/screens/other/order_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isCancelling = false;
  late String _currentStatus;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? 'unknown';

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить заказ?'),
        content: const Text('Мастер будет уведомлён. Это действие нельзя отменить.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await supabase
          .from('orders')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.order['id']);

      setState(() => _currentStatus = 'cancelled');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заказ отменён'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отмены: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Future<void> _generateOrderPdf() async {
    final pdf = PdfDocument();
    final page = pdf.pages.add();

    final service = widget.order['services'] ?? {};
    final specialist = widget.order['profiles'] ?? {};
    final details = widget.order['contract_details'] as Map<String, dynamic>? ?? {};

    final date = DateTime.parse(widget.order['created_at'] as String).toLocal();
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(date);

    // Заголовок
    page.graphics.drawString(
      'Заказ #${widget.order['id']}',
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 0, 500, 40),
    );

    // Дата
    page.graphics.drawString(
      'Создан: $formattedDate',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 50, 500, 20),
    );

    // Статус
    page.graphics.drawString(
      'Статус: ${_formatStatus(_currentStatus)}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 80, 500, 20),
    );

    // Исполнитель
    page.graphics.drawString(
      'Мастер: ${specialist['display_name'] ?? 'Не указан'}',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 120, 500, 30),
    );

    // Услуга
    page.graphics.drawString(
      'Услуга: ${service['name'] ?? 'Не указана'}',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 150, 500, 20),
    );

    // Цена
    page.graphics.drawString(
      'Цена: ${service['price'] ?? 'По договорённости'} BYN',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(0, 170, 500, 20),
    );

    // Детали контракта
    page.graphics.drawString(
      'Детали заказа:',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: const Rect.fromLTWH(0, 210, 500, 30),
    );

    double y = 240;
    details.forEach((key, value) {
      page.graphics.drawString(
        '$key: $value',
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: Rect.fromLTWH(0, y, 500, 20),
      );
      y += 25;
    });

    // Сохранение и открытие
    final bytes = await pdf.save();
    pdf.dispose();

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/order_${widget.order['id']}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    final openResult = await OpenFilex.open(filePath);
    if (openResult.type != ResultType.done) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка открытия PDF: ${openResult.message}')),
        );
      }
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'accepted':
        return colorScheme.secondary; // зелёный акцент
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_bottom_rounded;
      case 'accepted': return Icons.check_circle_rounded;
      case 'in_progress': return Icons.autorenew_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Неизвестно';
    final map = {
      'pending': 'Ожидает подтверждения',
      'accepted': 'Принят мастером',
      'in_progress': 'В работе',
      'completed': 'Завершён',
      'cancelled': 'Отменён',
    };
    return map[status] ?? status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final service = widget.order['services'] ?? {};
    final specialist = widget.order['profiles'] ?? {};
    final details = widget.order['contract_details'] as Map<String, dynamic>? ?? {};
    final createdDate = DateTime.parse(widget.order['created_at'] as String).toLocal();
    final updatedDate = widget.order['updated_at'] != null
        ? DateTime.parse(widget.order['updated_at'] as String).toLocal()
        : null;

    final formattedCreated = DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(createdDate);
    final formattedUpdated = updatedDate != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(updatedDate)
        : '—';

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text('Заказ #${widget.order['id']}'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Скачать PDF',
            onPressed: _generateOrderPdf,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Статус — большая карточка
                Card(
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(_currentStatus),
                          size: 48,
                          color: _getStatusColor(_currentStatus, colorScheme),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatStatus(_currentStatus),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(_currentStatus, colorScheme),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Создан: $formattedCreated',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (formattedUpdated != '—')
                                Text(
                                  'Обновлён: $formattedUpdated',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Мастер и услуга
                Card(
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Исполнитель и услуга',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundImage: specialist['photo_url'] != null
                                  ? NetworkImage(specialist['photo_url'])
                                  : null,
                              child: specialist['photo_url'] == null
                                  ? Text(
                                      (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? '?',
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontSize: 24,
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
                                    specialist['display_name'] ?? 'Мастер',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service['name'] ?? 'Услуга не указана',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  if (service['price'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${service['price']} BYN',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Детали заказа
                Card(
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Детали заказа',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.location_on_outlined, 'Адрес', details['address'] ?? 'Не указан'),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.calendar_today_outlined, 'Дата и время',
                            '${details['preferred_date'] ?? '—'} ${details['preferred_time'] ?? ''}'),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.timer_outlined, 'Продолжительность', details['duration'] ?? 'Не указана'),
                        if (details['comment'] != null && details['comment'].toString().isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            'Комментарий клиента:',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            details['comment'],
                            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Кнопка отмены (только для pending)
                if (_currentStatus == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isCancelling ? null : _cancelOrder,
                      icon: _isCancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cancel_rounded),
                      label: Text(_isCancelling ? 'Отмена...' : 'Отменить заказ'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: colorScheme.error.withOpacity(0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}