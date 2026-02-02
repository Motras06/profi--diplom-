import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../services/supabase_service.dart';
import 'change_password_dialog.dart';

typedef OnProfileSaved =
    Future<void> Function(
      String name,
      String? about,
      String? specialty,
      String? photoUrl,
    );

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

class _EditProfileFormState extends State<EditProfileForm>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _specialtyController;

  File? _newPhotoFile;
  final _picker = ImagePicker();

  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const int maxFileSizeBytes = 1024 * 1024;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);
    _aboutController = TextEditingController(text: widget.initialAbout ?? '');
    _specialtyController = TextEditingController(
      text: widget.initialSpecialty ?? '',
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _specialtyController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
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

    final tempFile = File(
      '${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  Future<String?> _uploadNewPhoto(String userId) async {
    if (_newPhotoFile == null) return widget.initialPhotoUrl;

    try {
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profile').upload(fileName, _newPhotoFile!);
      return supabase.storage.from('profile').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Ошибка загрузки фото: $e');
      return widget.initialPhotoUrl;
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Имя не может быть пустым')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final newPhotoUrl = await _uploadNewPhoto(userId);

      await widget.onSave(
        _nameController.text.trim(),
        _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
        _specialtyController.text.trim().isEmpty
            ? null
            : _specialtyController.text.trim(),
        newPhotoUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Card(
                elevation: 16,
                shadowColor: colorScheme.shadow.withOpacity(0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickAndCompressPhoto,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 80,
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundImage: _newPhotoFile != null
                                    ? FileImage(_newPhotoFile!)
                                    : (widget.initialPhotoUrl != null
                                          ? NetworkImage(
                                              widget.initialPhotoUrl!,
                                            )
                                          : null),
                                child:
                                    (_newPhotoFile == null &&
                                        widget.initialPhotoUrl == null)
                                    ? Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0]
                                                  .toUpperCase()
                                            : 'М',
                                        style: TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : null,
                              ),
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: colorScheme.primary,
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя *',
                          prefixIcon: const Icon(Icons.person_rounded),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _specialtyController,
                        decoration: InputDecoration(
                          labelText: 'Специальность',
                          prefixIcon: const Icon(Icons.work_rounded),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _aboutController,
                        maxLines: 6,
                        minLines: 4,
                        decoration: InputDecoration(
                          labelText: 'О себе',
                          prefixIcon: const Icon(Icons.info_outline_rounded),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 32),

                      OutlinedButton.icon(
                        onPressed: () => ChangePasswordDialog.show(context),
                        icon: const Icon(Icons.key_rounded),
                        label: const Text('Сменить пароль'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: colorScheme.shadow.withOpacity(0.18),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : widget.onCancel,
                              child: const Text('Отмена'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurfaceVariant,
                                side: BorderSide(color: colorScheme.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 2,
                                shadowColor: colorScheme.shadow.withOpacity(
                                  0.18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSaving ? null : _save,
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 4,
                                shadowColor: colorScheme.primary.withOpacity(
                                  0.4,
                                ),
                              ),
                              child: _isSaving
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Text('Сохранить'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
