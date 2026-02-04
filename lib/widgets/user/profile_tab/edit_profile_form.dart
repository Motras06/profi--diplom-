import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:prowirksearch/widgets/specialist/profile_tab/change_password_dialog.dart';
import '../../../services/supabase_service.dart';

typedef OnProfileSaved = Future<void> Function(String name, String? photoUrl);

class EditProfileForm extends StatefulWidget {
  final String initialName;
  final String? initialPhotoUrl;
  final OnProfileSaved onSave;
  final VoidCallback onCancel;

  const EditProfileForm({
    super.key,
    required this.initialName,
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
  File? _newPhotoFile;
  bool _isSaving = false;

  static const int maxFileSizeBytes = 1 * 1024 * 1024;
  late AnimationController _avatarAnimController;
  late Animation<double> _avatarScaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);

    _avatarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _avatarScaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _avatarAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.initialPhotoUrl != null ||
        widget.initialName.trim().isNotEmpty) {
      _avatarAnimController.forward();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (picked == null) return;

    final original = File(picked.path);
    setState(() => _newPhotoFile = original);

    final compressed = await _compressToUnder1MB(original);
    if (compressed != null && mounted) {
      setState(() => _newPhotoFile = compressed);
      _avatarAnimController.forward(from: 0.0);
    }
  }

  Future<File?> _compressToUnder1MB(File file) async {
    try {
      Uint8List bytes = await file.readAsBytes();
      int quality = 88;

      while (quality > 20 && bytes.lengthInBytes > maxFileSizeBytes) {
        img.Image? image = img.decodeImage(bytes);
        if (image == null) break;
        if (image.width > 900 || image.height > 900) {
          image = img.copyResize(image, width: 900);
        }
        bytes = img.encodeJpg(image, quality: quality);
        quality -= 12;
      }

      final tempFile = File(
        '${Directory.systemTemp.path}/compressed_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (_) {
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки фото: $e')));
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

    setState(() => _isSaving = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final newPhotoUrl = await _uploadNewPhoto(userId);
      await widget.onSave(name, newPhotoUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Не удалось сохранить: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(
              'Редактирование профиля',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите на фото, чтобы выбрать новое изображение.\n'
              'Максимальный размер — около 1 МБ, фото будет автоматически оптимизировано.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : _pickAndCompressPhoto,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 480),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: _avatarScaleAnimation,
                      child: child,
                    ),
                  ),
                  child: Stack(
                    key: ValueKey<bool>(_newPhotoFile != null),
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer.withOpacity(0.2),
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.transparent,
                          foregroundImage: _newPhotoFile != null
                              ? FileImage(_newPhotoFile!)
                              : (widget.initialPhotoUrl != null
                                    ? NetworkImage(widget.initialPhotoUrl!)
                                    : null),
                          child:
                              (_newPhotoFile == null &&
                                  widget.initialPhotoUrl == null)
                              ? Text(
                                  _nameController.text.trim().isNotEmpty
                                      ? _nameController.text
                                            .trim()[0]
                                            .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 72,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: ShapeDecoration(
                            color: colorScheme.primary,
                            shape: const CircleBorder(),
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 22,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      if (_isSaving)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              enabled: !_isSaving,
              decoration: InputDecoration(
                labelText: 'Имя или никнейм',
                helperText: 'Как вас будут видеть другие пользователи',
                helperStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.person_rounded),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 40),

            OutlinedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => ChangePasswordDialog.show(context),
              icon: const Icon(Icons.key_rounded, size: 20),
              label: const Text('Сменить пароль'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 48),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.shrink()
                        : const Icon(Icons.save_rounded, size: 20),
                    label: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Text('Сохранить изменения'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
