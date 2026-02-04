import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:profi/services/supabase_service.dart';

class ComplaintsTab extends StatefulWidget {
  const ComplaintsTab({super.key});

  @override
  State<ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<ComplaintsTab> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Список возможных статусов и их отображаемые названия
  final List<String> _statusOptions = [
    'pending',
    'reviewed',
    'resolved',
    'rejected',
    'escalated',
  ];

  final Map<String, String> _statusDisplay = {
    'pending': 'Ожидает проверки',
    'reviewed': 'Проверено',
    'resolved': 'Решено',
    'rejected': 'Отклонено',
    'escalated': 'Эскалация',
  };

  // Для отслеживания, какой статус редактируется (чтобы кнопка "Сохранить" была активна)
  Map<int, String> _editingStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _editingStatuses.clear(); // сбрасываем редактирование
    });

    try {
      final response = await supabase
          .from('complaints')
          .select('''
            id, complainant_id, target_type, target_id, reason, details, status,
            created_at, updated_at,
            complainant:profiles!complainant_id (display_name)
          ''')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки жалоб: $e');
      setState(() {
        _errorMessage = 'Не удалось загрузить жалобы: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveStatus(int complaintId, String newStatus) async {
    try {
      await supabase
          .from('complaints')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', complaintId);

      // Обновляем локально
      setState(() {
        final index = _complaints.indexWhere((c) => c['id'] == complaintId);
        if (index != -1) {
          _complaints[index]['status'] = newStatus;
        }
        _editingStatuses.remove(complaintId); // снимаем режим редактирования
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статус обновлён: ${_formatComplaintStatus(newStatus)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка сохранения статуса: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось сохранить: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'escalated':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatComplaintStatus(String status) {
    return _statusDisplay[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: RefreshIndicator.adaptive(
        onRefresh: _loadComplaints,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _loadComplaints,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                : _complaints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 88,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(height: 32),
                            Text('Жалоб пока нет', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 12),
                            Text(
                              'Когда пользователи пожалуются — они появятся здесь',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];

                          final complainant = complaint['complainant'] as Map<String, dynamic>?;
                          final complainantName = complainant?['display_name'] as String? ??
                              'ID ${complaint['complainant_id'].toString().substring(0, 8)}';

                          final targetType = complaint['target_type'] as String? ?? '—';
                          final reason = complaint['reason'] as String? ?? 'Не указана';
                          final details = complaint['details'] as String? ?? '—';
                          final status = complaint['status'] as String? ?? 'pending';
                          final createdAt = _formatDate(complaint['created_at'] as String?);
                          final complaintId = complaint['id'] as int;

                          // Текущий редактируемый статус (если пользователь начал менять)
                          final currentEditingStatus = _editingStatuses[complaintId] ?? status;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ExpansionTile(
                              leading: Icon(Icons.flag, color: _getStatusColor(status)),
                              title: Text(
                                'Жалоба от $complainantName',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Статус: ${_formatComplaintStatus(status)} • $createdAt',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              children: [
                                ListTile(
                                  dense: true,
                                  title: const Text('Тип объекта'),
                                  subtitle: Text(targetType),
                                ),
                                ListTile(
                                  dense: true,
                                  title: const Text('Причина'),
                                  subtitle: Text(reason),
                                ),
                                if (details != '—')
                                  ListTile(
                                    dense: true,
                                    title: const Text('Подробности'),
                                    subtitle: Text(details),
                                  ),

                                // Блок редактирования статуса
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: currentEditingStatus,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            labelText: 'Изменить статус',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          items: _statusOptions.map((s) {
                                            return DropdownMenuItem<String>(
                                              value: s,
                                              child: Text(_formatComplaintStatus(s)),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            if (newValue != null) {
                                              setState(() {
                                                _editingStatuses[complaintId] = newValue;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: currentEditingStatus != status
                                            ? () => _saveStatus(complaintId, currentEditingStatus)
                                            : null, // кнопка активна только если статус изменился
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor: colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Сохранить'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}