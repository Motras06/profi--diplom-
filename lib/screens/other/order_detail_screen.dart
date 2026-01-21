// lib/screens/other/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final supabase = Supabase.instance.client;
  bool _isCancelling = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? 'unknown';
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить заказ'),
        content: const Text('Вы уверены? Мастер будет уведомлён.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Да, отменить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await supabase
          .from('orders')
          .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.order['id']);

      setState(() => _currentStatus = 'cancelled');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заказ отменён'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отмены: $e')),
      );
    } finally {
      setState(() => _isCancelling = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.purple;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'accepted': return Icons.check_circle_outline;
      case 'in_progress': return Icons.autorenew;
      case 'completed': return Icons.done_all;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.order['services'] ?? {};
    final specialist = widget.order['profiles'] ?? {};
    final details = widget.order['contract_details'] as Map<String, dynamic>? ?? {};
    final date = (widget.order['created_at'] as String?)?.split('T')[0] ?? '—';
    final updated = (widget.order['updated_at'] as String?)?.split('T')[0] ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${widget.order['id']}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(_currentStatus), color: _getStatusColor(_currentStatus), size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatStatus(_currentStatus),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(_currentStatus),
                            ),
                          ),
                          Text('Создан: $date • Обновлён: $updated'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Услуга и мастер
            ListTile(
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: specialist['photo_url'] != null ? NetworkImage(specialist['photo_url']) : null,
                child: specialist['photo_url'] == null
                    ? Text(specialist['display_name']?[0] ?? '?', style: const TextStyle(fontSize: 24))
                    : null,
              ),
              title: Text(service['name'] ?? 'Услуга', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text('Мастер: ${specialist['display_name'] ?? 'Неизвестен'}'),
            ),
            const Divider(height: 32),

            // Детали заказа
            const Text('Детали заказа', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _DetailRow('Адрес', details['address'] ?? 'Не указан'),
            _DetailRow('Дата и время', '${details['preferred_date'] ?? '—'} ${details['preferred_time'] ?? ''}'),
            _DetailRow('Продолжительность', details['duration'] ?? 'Не указана'),
            if (details['comment'] != null) ...[
              const SizedBox(height: 12),
              const Text('Комментарий:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(details['comment'], style: const TextStyle(fontSize: 15)),
            ],

            const SizedBox(height: 40),

            // Кнопка отмены (только если pending)
            if (_currentStatus == 'pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _cancelOrder,
                  icon: _isCancelling
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cancel, color: Colors.red),
                  label: Text(
                    _isCancelling ? 'Отмена...' : 'Отменить заказ',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Неизвестно';
    return status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
  }
}