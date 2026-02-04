import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:developer' as developer;

class SpecialistDocumentsScreen extends StatefulWidget {
  final String specialistId;
  final String specialistName;

  const SpecialistDocumentsScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });

  @override
  State<SpecialistDocumentsScreen> createState() =>
      _SpecialistDocumentsScreenState();
}

class _SpecialistDocumentsScreenState extends State<SpecialistDocumentsScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final response = await supabase
          .from('documents')
          .select('id, name, file_url, description, created_at')
          .eq('specialist_id', widget.specialistId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _documents = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Ошибка загрузки документов: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить документы: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndOpenFile(Map<String, dynamic> doc) async {
    final url = doc['file_url'] as String?;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка на файл отсутствует')),
      );
      return;
    }

    try {
      final dio = Dio();
      final fileName =
          doc['name'] as String? ??
          'document_${DateTime.now().millisecondsSinceEpoch}';

      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Не удалось получить папку загрузок');
      }

      final savePath = '${directory.path}/$fileName';

      await dio.download(url, savePath);

      final result = await OpenFilex.open(savePath);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть файл: ${result.message}')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Файл сохранён: $fileName')));
      }
    } catch (e) {
      developer.log('Ошибка скачивания: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при скачивании: $e')));
      }
    }
  }

  IconData _getIconForFile(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'xls' || 'xlsx' => Icons.table_chart,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' => Icons.image,
      'zip' || 'rar' || '7z' => Icons.archive,
      _ => Icons.insert_drive_file,
    };
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Документы ${widget.specialistName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
          ? Center(
              child: Text(
                'Нет документов',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                final name = doc['name'] as String? ?? 'Без названия';
                final desc = doc['description'] as String?;
                final date = _formatDate(doc['created_at'] as String?);

                return ListTile(
                  leading: Icon(
                    _getIconForFile(name),
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: desc != null && desc.isNotEmpty
                      ? Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis)
                      : Text(
                          'Добавлен $date',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () => _downloadAndOpenFile(doc),
                  ),
                  onTap: () => _downloadAndOpenFile(doc),
                );
              },
            ),
    );
  }
}
