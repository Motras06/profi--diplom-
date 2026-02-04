import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/supabase_service.dart';

class AddEditServiceDialog {
  static Future<void> show({
    required BuildContext context,
    Map<String, dynamic>? service,
    required VoidCallback onSaved,
  }) async {
    final isEdit = service != null;
    final nameController = TextEditingController(
      text: service?['name'] as String? ?? '',
    );
    final descriptionController = TextEditingController(
      text: service?['description'] as String? ?? '',
    );
    final priceController = TextEditingController(
      text: service?['price']?.toString() ?? '',
    );

    List<String> currentPhotos = List<String>.from(service?['photos'] ?? []);

    List<String> newPhotoPaths = [];

    final _picker = ImagePicker();
    const int maxFileSizeBytes = 1024 * 1024;
    const int maxPhotos = 3;

    Future<File?> _compressToUnder1MB(File file) async {
      try {
        Uint8List bytes = await file.readAsBytes();
        int quality = 90;

        while (quality > 10 && bytes.lengthInBytes > maxFileSizeBytes) {
          img.Image? image = img.decodeImage(bytes);
          if (image == null) break;

          if (image.width > 800 || image.height > 800) {
            image = img.copyResize(image, width: 800);
          }

          bytes = img.encodeJpg(image, quality: quality);
          quality -= 10;
        }

        final tempFile = File(
          '${Directory.systemTemp.path}/service_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await tempFile.writeAsBytes(bytes);
        return tempFile;
      } catch (e) {
        debugPrint('Ошибка сжатия фото: $e');
        return null;
      }
    }

    Future<List<String>> _pickAndCompressPhotos() async {
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Разрешение на доступ к фото отклонено'),
            ),
          );
          return [];
        }
      }

      final picked = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked.isEmpty) return [];

      List<String> compressedPaths = [];

      for (var xfile in picked.take(
        maxPhotos - currentPhotos.length - newPhotoPaths.length,
      )) {
        final originalFile = File(xfile.path);
        final compressed = await _compressToUnder1MB(originalFile);
        if (compressed != null) {
          compressedPaths.add(compressed.path);
        }
      }

      return compressedPaths;
    }

    Future<void> _uploadPhotos(int serviceId, List<String> paths) async {
      for (int i = 0; i < paths.length; i++) {
        final file = File(paths[i]);
        final fileName =
            '$serviceId/photo_${currentPhotos.length + i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage.from('service_photos').upload(fileName, file);

        final url = supabase.storage
            .from('service_photos')
            .getPublicUrl(fileName);

        await supabase.from('service_photos').insert({
          'service_id': serviceId,
          'photo_url': url,
          'order': currentPhotos.length + i + 1,
        });
      }
    }

    Future<void> _deletePhotoFromDb(int serviceId, String photoUrl) async {
      try {
        await supabase
            .from('service_photos')
            .delete()
            .eq('service_id', serviceId)
            .eq('photo_url', photoUrl);
      } catch (e) {
        debugPrint('Ошибка удаления фото из базы: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Редактировать услугу' : 'Новая услуга'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название услуги *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Цена (BYN)',
                    border: OutlineInputBorder(),
                    prefixText: 'BYN ',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Фото услуги (до 3)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...currentPhotos.map(
                      (url) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    color: Colors.red,
                                  ),
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 28,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  currentPhotos.remove(url);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...newPhotoPaths.map(
                      (path) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (currentPhotos.length + newPhotoPaths.length < maxPhotos)
                      GestureDetector(
                        onTap: () async {
                          final paths = await _pickAndCompressPhotos();
                          setDialogState(() {
                            newPhotoPaths.addAll(paths);
                          });
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название услуги')),
                  );
                  return;
                }

                final userId = supabase.auth.currentUser?.id;
                if (userId == null) return;

                try {
                  int serviceId;

                  if (isEdit) {
                    serviceId = service!['id'] as int;

                    await supabase
                        .from('services')
                        .update({
                          'name': name,
                          'description':
                              descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          'price': priceController.text.trim().isEmpty
                              ? null
                              : double.tryParse(priceController.text.trim()),
                        })
                        .eq('id', serviceId);

                    final existingPhotos =
                        (service['photos'] as List?)?.cast<String>() ?? [];
                    final toDelete = existingPhotos
                        .where((url) => !currentPhotos.contains(url))
                        .toList();

                    for (var url in toDelete) {
                      await _deletePhotoFromDb(serviceId, url);
                    }
                  } else {
                    final resp = await supabase
                        .from('services')
                        .insert({
                          'specialist_id': userId,
                          'name': name,
                          'description':
                              descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          'price': priceController.text.trim().isEmpty
                              ? null
                              : double.tryParse(priceController.text.trim()),
                        })
                        .select('id')
                        .single();

                    serviceId = resp['id'] as int;
                  }

                  if (newPhotoPaths.isNotEmpty) {
                    await _uploadPhotos(serviceId, newPhotoPaths);
                  }

                  Navigator.pop(ctx);
                  onSaved();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Услуга обновлена' : 'Услуга добавлена',
                        ),
                      ),
                    );
                  }
                } catch (e, stack) {
                  debugPrint('Ошибка сохранения услуги: $e\n$stack');
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
