import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prowirksearch/screens/specialist/specialist_home.dart';
import 'package:prowirksearch/screens/user/user_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

enum UserRole { user, specialist }

class RegisterTab extends StatefulWidget {
  const RegisterTab({super.key});

  @override
  State<RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<RegisterTab>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _aboutController = TextEditingController();

  String? _selectedSpecialty;

  UserRole _selectedRole = UserRole.user;
  File? _originalImage;
  File? _compressedImage;
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _picker = ImagePicker();

  static const int maxFileSizeBytes = 1024 * 1024;

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

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.20), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressImage() async {
    if (_isLoading) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );

    if (picked == null) return;

    final originalFile = File(picked.path);
    setState(() {
      _originalImage = originalFile;
      _compressedImage = null;
      _isLoading = true;
    });

    final compressedFile = await _compressImageToUnder1MB(originalFile);

    if (mounted) {
      setState(() {
        _compressedImage = compressedFile;
        _isLoading = false;
      });
    }
  }

  Future<File?> _compressImageToUnder1MB(File originalFile) async {
    Uint8List bytes = await originalFile.readAsBytes();
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

    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/avatar_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(bytes);

    return tempFile;
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_compressedImage == null) return null;

    try {
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage
          .from('profile')
          .upload(fileName, _compressedImage!);
      return supabase.storage.from('profile').getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ошибка загрузки фото'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _registerAndNavigate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Пароли не совпадают'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_selectedRole == UserRole.specialist && _selectedSpecialty == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите специальность')));
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userId = authResponse.user?.id;
      if (userId == null) throw 'Ошибка создания пользователя';

      final photoUrl = await _uploadAvatar(userId);

      final role = _selectedRole == UserRole.user ? 'user' : 'specialist';

      await supabase.from('profiles').insert({
        'id': userId,
        'role': role,
        'display_name': _displayNameController.text.trim(),
        'photo_url': photoUrl,
        'about': _selectedRole == UserRole.specialist
            ? _aboutController.text.trim()
            : null,
        'specialty': _selectedRole == UserRole.specialist
            ? _selectedSpecialty
            : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Регистрация успешна!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Widget destination = _selectedRole == UserRole.specialist
            ? SpecialistHome(displayName: _displayNameController.text.trim())
            : UserHome(displayName: _displayNameController.text.trim());

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка регистрации')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(80),
                    onTap: _pickAndCompressImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Material(
                          elevation: 2,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            backgroundImage: _compressedImage != null
                                ? FileImage(_compressedImage!)
                                : (_originalImage != null
                                      ? FileImage(_originalImage!)
                                      : null),
                            child:
                                (_compressedImage == null &&
                                    _originalImage == null)
                                ? Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 48,
                                    color: colorScheme.primary,
                                  )
                                : null,
                          ),
                        ),
                        if (_isLoading && _compressedImage == null)
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                              strokeWidth: 4,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _compressedImage != null
                      ? 'Фото загружено (${(_compressedImage!.lengthSync() ~/ 1024).toStringAsFixed(0)} КБ)'
                      : _isLoading
                      ? 'Сжатие изображения...'
                      : 'Нажмите на фото, чтобы выбрать аватар (опционально)',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                SegmentedButton<UserRole>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurface,
                    selectedBackgroundColor: colorScheme.primaryContainer,
                    selectedForegroundColor: colorScheme.onPrimaryContainer,
                    side: BorderSide(color: colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(value: UserRole.user, label: Text('Клиент')),
                    ButtonSegment(
                      value: UserRole.specialist,
                      label: Text('Исполнитель'),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: (set) =>
                      setState(() => _selectedRole = set.first),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _displayNameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.trim().isEmpty ? 'Введите имя' : null,
                  decoration: InputDecoration(
                    labelText: 'Отображаемое имя *',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.trim().isEmpty || !v.contains('@')
                      ? 'Неверный email'
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v!.length < 6 ? 'Минимум 6 символов' : null,
                  decoration: InputDecoration(
                    labelText: 'Пароль *',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Подтвердите пароль *',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                if (_selectedRole == UserRole.specialist) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _aboutController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'О себе',
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      prefixIcon: Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    hint: const Text('Выберите специальность *'),
                    isExpanded: true,
                    items: _availableSpecialties.map((specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSpecialty = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Выберите специальность' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      prefixIcon: Icon(
                        Icons.work_outline,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                FilledButton.icon(
                  onPressed: _isLoading ? null : _registerAndNavigate,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.person_add_rounded),
                  label: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Зарегистрироваться'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
