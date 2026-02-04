import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/date_symbol_data_local.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isCancelling = false;
  late String _currentStatus;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future<Uint8List>? _fontFuture;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] as String? ?? 'unknown';

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

    _fontFuture = _loadFont();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  Future<Uint8List> _loadFont() async {
    try {
      final fontData = await DefaultAssetBundle.of(
        context,
      ).load('assets/fonts/DejaVuSans.ttf');
      return fontData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Ошибка загрузки шрифта: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _generateOrderPdf() async {
    if (!mounted) return;

    try {
      await initializeDateFormatting('ru');

      final fontBytes = await _fontFuture;

      final pdf = PdfDocument();

      pdf.pageSettings.size = PdfPageSize.a4;
      pdf.pageSettings.margins.all = 40;
      pdf.pageSettings.orientation = PdfPageOrientation.portrait;

      final ttf = PdfTrueTypeFont(fontBytes!, 12);
      final boldFont = PdfTrueTypeFont(fontBytes, 14, style: PdfFontStyle.bold);

      final page = pdf.pages.add();
      final pageGraphics = page.graphics;

      final service = widget.order['services'] as Map? ?? {};
      final specialist = widget.order['profiles'] as Map? ?? {};
      final details = widget.order['contract_details'] as Map? ?? {};

      final createdAtRaw = widget.order['created_at'] as String?;
      final date = createdAtRaw != null && createdAtRaw.isNotEmpty
          ? DateTime.tryParse(createdAtRaw)?.toLocal() ?? DateTime.now()
          : DateTime.now();
      final formattedDate = DateFormat(
        'dd MMMM yyyy, HH:mm',
        'ru',
      ).format(date);

      double y = page.getClientSize().height - 80;

      pageGraphics.drawString(
        'Заказ #${widget.order['id'] ?? '—'}',
        boldFont,
        brush: PdfSolidBrush(PdfColor(0, 102, 204)),
        bounds: Rect.fromLTWH(0, y, page.getClientSize().width, 40),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      y -= 60;

      pageGraphics.drawString(
        'Создан: $formattedDate',
        ttf,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(40, y, page.getClientSize().width - 80, 25),
      );
      y -= 45;

      final statusText = _formatStatus(_currentStatus);
      final statusColor = _getStatusColor(
        _currentStatus,
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

      pageGraphics.drawRectangle(
        brush: PdfSolidBrush(PdfColor(220, 220, 220)),
        bounds: Rect.fromLTWH(40, y, page.getClientSize().width - 80, 1),
      );
      y -= 40;

      _drawLabelValue(
        pageGraphics,
        ttf,
        boldFont,
        'Мастер',
        specialist['display_name'] ?? 'Не указан',
        40,
        y,
        page.getClientSize().width,
      );
      y -= 35;

      _drawLabelValue(
        pageGraphics,
        ttf,
        boldFont,
        'Услуга',
        service['name'] ?? 'Не указана',
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

      pageGraphics.drawString(
        'Сгенерировано в приложении • ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
        ttf,
        brush: PdfSolidBrush(PdfColor(140, 140, 140)),
        bounds: Rect.fromLTWH(40, 40, page.getClientSize().width - 80, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      final bytes = await pdf.save();
      pdf.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/order_${widget.order['id'] ?? 'unknown'}.pdf';
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
            content: Text('Не удалось открыть PDF: ${result.message}'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('PDF error: $e\n$stack');
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
    double pageWidth,
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
      bounds: Rect.fromLTWH(x + 210, y, pageWidth - x - 250, 120),
      format: PdfStringFormat(lineSpacing: 4, wordWrap: PdfWordWrapType.word),
    );
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить заказ?'),
        content: const Text(
          'Мастер будет уведомлён. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка отмены: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
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

  IconData _getStatusIcon(String status) {
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
        return Icons.help_outline_rounded;
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
    return map[status] ??
        status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final orderId = widget.order['id']?.toString() ?? '—';
    final status = widget.order['status'] as String? ?? 'unknown';
    final createdAtRaw = widget.order['created_at'] as String?;
    final updatedAtRaw = widget.order['updated_at'] as String?;

    final service = widget.order['services'] as Map<String, dynamic>? ?? {};
    final specialist = widget.order['profiles'] as Map<String, dynamic>? ?? {};
    final details =
        widget.order['contract_details'] as Map<String, dynamic>? ?? {};

    String formattedCreated = '—';
    String formattedUpdated = '—';

    if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
      try {
        final date = DateTime.parse(createdAtRaw).toLocal();
        formattedCreated = DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(date);
      } catch (_) {}
    }

    if (updatedAtRaw != null && updatedAtRaw.isNotEmpty) {
      try {
        final date = DateTime.parse(updatedAtRaw).toLocal();
        formattedUpdated = DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(date);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Заказ #$orderId',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 48,
                            color: _getStatusColor(status, colorScheme),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatStatus(status),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _getStatusColor(status, colorScheme),
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

                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Исполнитель и услуга',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundImage: specialist['photo_url'] != null
                                    ? NetworkImage(
                                        specialist['photo_url'] as String,
                                      )
                                    : null,
                                child: specialist['photo_url'] == null
                                    ? Text(
                                        (specialist['display_name'] as String?)
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            '?',
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
                                      specialist['display_name'] as String? ??
                                          'Мастер',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      service['name'] as String? ??
                                          'Услуга не указана',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    if (service['price'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${service['price']} BYN',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
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

                  Card(
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Детали заказа',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            Icons.location_on_outlined,
                            'Адрес',
                            details['address'] as String? ?? 'Не указан',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.calendar_today_outlined,
                            'Дата и время',
                            '${details['preferred_date'] as String? ?? '—'} ${details['preferred_time'] as String? ?? ''}',
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.timer_outlined,
                            'Продолжительность',
                            details['duration'] as String? ?? 'Не указана',
                          ),
                          if ((details['comment'] as String?)?.isNotEmpty ??
                              false) ...[
                            const Divider(height: 24),
                            Text(
                              'Комментарий клиента:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              details['comment'] as String,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

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
                        label: Text(
                          _isCancelling ? 'Отмена...' : 'Отменить заказ',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
