// lib/widgets/specialist/profile_tab/documents.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class SpecialistDocuments extends StatefulWidget {
  const SpecialistDocuments({super.key});

  @override
  State<SpecialistDocuments> createState() => _SpecialistDocumentsState();
}

class _SpecialistDocumentsState extends State<SpecialistDocuments> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];

  final String _tableName = 'documents';   // таблица в БД
  final String _bucketName = 'document';   // бакет в Storage

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('Пользователь не авторизован');

      final response = await supabase
          .from(_tableName)  // documents
          .select('*')
          .eq('specialist_id', currentUser.id)
          .order('created_at', ascending: false);

      setState(() {
        _documents = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDocument() async {
    try {
      await Future.delayed(Duration.zero);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final filePath = file.path;
      if (filePath == null) return;

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${currentUser.id}/$timestamp-${file.name}';

      // Загрузка в бакет 'document'
      await supabase.storage.from(_bucketName).upload(
        fileName,
        File(filePath),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final publicUrl = supabase.storage.from(_bucketName).getPublicUrl(fileName);

      // Диалог
      String displayName = file.name;
      String? description;

      await showDialog(
        context: context,
        builder: (ctx) {
          final nameCtrl = TextEditingController(text: displayName);
          final descCtrl = TextEditingController();
          return AlertDialog(
            title: const Text('Детали документа'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Название')),
                const SizedBox(height: 16),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Описание (опционально)'), minLines: 2, maxLines: 4),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              FilledButton(
                onPressed: () {
                  displayName = nameCtrl.text.trim().isEmpty ? file.name : nameCtrl.text.trim();
                  description = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      );

      await supabase.from(_tableName).insert({
        'specialist_id': currentUser.id,
        'file_url': publicUrl,
        'name': displayName,
        'description': description,
      });

      await _loadDocuments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Документ добавлен')),
        );
      }
    } catch (e, stack) {
      debugPrint('Error in _addDocument: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _downloadAndOpen(String fileUrl, String fileName) async {
    try {
      // Извлекаем путь внутри бакета 'document'
      final uri = Uri.parse(fileUrl);
      final pathInBucket = uri.pathSegments.skipWhile((s) => s != _bucketName).skip(1).join('/');

      final signedUrl = await supabase.storage.from(_bucketName).createSignedUrl(pathInBucket, 3600);

      final dir = Platform.isAndroid ? await getExternalStorageDirectory() : await getTemporaryDirectory();
      final savePath = '${dir!.path}/$fileName';

      final dio = Dio();
      await dio.download(signedUrl, savePath);

      final openResult = await OpenFile.open(savePath);
      if (openResult.type != ResultType.done) {
        throw Exception(openResult.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка скачивания/открытия: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'ru').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои документы'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 32),
                        const Text('У вас нет загруженных документов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text('Добавьте сертификаты, дипломы или лицензии,\nчтобы повысить доверие клиентов', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final name = doc['name'] as String? ?? 'Без названия';
                      final description = doc['description'] as String? ?? 'Нет описания';
                      final fileUrl = doc['file_url'] as String;
                      final createdAt = DateTime.parse(doc['created_at'] as String);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(Icons.description, color: theme.colorScheme.primary, size: 40),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(description, style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 4),
                              Text('Добавлен: ${_formatDate(createdAt)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _downloadAndOpen(fileUrl, name),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(Icons.add),
        label: const Text('Добавить документ'),
      ),
    );
  }
}