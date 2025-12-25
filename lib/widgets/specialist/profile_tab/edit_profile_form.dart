// lib/widgets/specialist/profile_tab/edit_profile_form.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import 'change_password_dialog.dart'; // Импортируем диалог

typedef OnProfileSaved = Future<void> Function(String name, String? about, String? specialty, String? photoUrl);

class EditProfileForm extends StatefulWidget {
  final String initialName;
  final String? initialAbout;
  final String? initialSpecialty;
  final String? initialPhotoUrl;
  final OnProfileSaved onSave;
  final VoidCallback onCancel;

  const EditProfileForm({
    super.key,
    required this.initialName,
    this.initialAbout,
    this.initialSpecialty,
    this.initialPhotoUrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _specialtyController;

  File? _newPhotoFile;
  final _picker = ImagePicker();

  bool _isSaving = false;

  static const int maxFileSizeBytes = 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _aboutController = TextEditingController(text: widget.initialAbout ?? '');
    _specialtyController = TextEditingController(text: widget.initialSpecialty ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked == null) return;

    final originalFile = File(picked.path);
    setState(() => _newPhotoFile = originalFile);

    final compressed = await _compressToUnder1MB(originalFile);
    if (mounted && compressed != null) {
      setState(() => _newPhotoFile = compressed);
    }
  }

  Future<File?> _compressToUnder1MB(File file) async {
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

    final tempFile = File('${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<String?> _uploadNewPhoto(String userId) async {
    if (_newPhotoFile == null) return widget.initialPhotoUrl;

    try {
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profile').upload(fileName, _newPhotoFile!);
      return supabase.storage.from('profile').getPublicUrl(fileName);
    } catch (e) {
      return widget.initialPhotoUrl;
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Имя не может быть пустым')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final newPhotoUrl = await _uploadNewPhoto(userId);

      await widget.onSave(
        _nameController.text.trim(),
        _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
        _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
        newPhotoUrl,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndCompressPhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  backgroundImage: _newPhotoFile != null
                      ? FileImage(_newPhotoFile!)
                      : (widget.initialPhotoUrl != null ? NetworkImage(widget.initialPhotoUrl!) : null),
                  child: (_newPhotoFile == null && widget.initialPhotoUrl == null)
                      ? Text(
                          _nameController.text[0].toUpperCase(),
                          style: TextStyle(fontSize: 64, color: colorScheme.primary),
                        )
                      : null,
                ),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Имя',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _specialtyController,
            decoration: const InputDecoration(
              labelText: 'Специальность',
              prefixIcon: Icon(Icons.work),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aboutController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'О себе',
              prefixIcon: Icon(Icons.info),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => ChangePasswordDialog.show(context),
            icon: const Icon(Icons.key),
            label: const Text('Сменить пароль'),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}