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
  late TextEditingController _customSpecialtyController;

  String? _selectedSpecialty;
  bool _showCustomSpecialtyField = false;

  final List<String> _availableSpecialties = [
    'Сантехника',
    'Электрика',
    'Ремонт квартир',
    'Отделка и штукатурка',
    'Уборка / Клининг',
    'Красота / Парикмахер',
    'Маникюр / Педикюр',
    'Массаж',
    'Авторемонт',
    'Автомойка / детейлинг',
    'IT / Программирование',
    'Дизайн интерьера',
    'Фото / Видео',
    'Репетиторство',
    'Перевозки / Грузчики',
    'Сад / Огород',
    'Ветеринар',
    'Психология / Коучинг',
    'Другое',
  ];

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
    _customSpecialtyController = TextEditingController();

    final initial = widget.initialSpecialty;
    if (initial != null && initial.isNotEmpty) {
      if (_availableSpecialties.contains(initial)) {
        _selectedSpecialty = initial;
      } else {
        _selectedSpecialty = 'Другое';
        _customSpecialtyController.text = initial;
        _showCustomSpecialtyField = true;
      }
    }

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
    _customSpecialtyController.dispose();
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
        '${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      debugPrint('Ошибка сжатия фото: $e');
      return null;
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить фото: $e')),
        );
      }
      return widget.initialPhotoUrl;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Имя не может быть пустым')));
      return;
    }

    String? finalSpecialty;

    if (_selectedSpecialty == 'Другое') {
      final custom = _customSpecialtyController.text.trim();
      finalSpecialty = custom.isNotEmpty ? custom : null;
    } else {
      finalSpecialty = _selectedSpecialty;
    }

    setState(() => _isSaving = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final newPhotoUrl = await _uploadNewPhoto(userId);

      await widget.onSave(
        name,
        _aboutController.text.trim().isEmpty
            ? null
            : _aboutController.text.trim(),
        finalSpecialty,
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
        title: Text(
          'Редактировать профиль',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
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

                      DropdownButtonFormField<String>(
                        value: _selectedSpecialty,
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
                        items: _availableSpecialties.map((specialty) {
                          return DropdownMenuItem<String>(
                            value: specialty,
                            child: Text(specialty),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialty = value;
                            _showCustomSpecialtyField = value == 'Другое';
                            if (value != 'Другое') {
                              _customSpecialtyController.clear();
                            }
                          });
                        },
                        hint: const Text('Выберите специальность'),
                      ),
                      const SizedBox(height: 16),

                      if (_showCustomSpecialtyField) ...[
                        TextField(
                          controller: _customSpecialtyController,
                          decoration: InputDecoration(
                            labelText: 'Укажите свою специальность',
                            prefixIcon: const Icon(Icons.edit_rounded),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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
