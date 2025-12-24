// lib/screens/auth/register_tab.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:profi/screens/specialist/specialist_home.dart';
import 'package:profi/screens/user/user_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

enum UserRole { user, specialist }

class RegisterTab extends StatefulWidget {
  const RegisterTab({super.key});

  @override
  State<RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _specialtyController = TextEditingController();

  UserRole _selectedRole = UserRole.user;
  File? _originalImage;
  File? _compressedImage;
  bool _isLoading = false;

  // Состояние видимости паролей
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final _picker = ImagePicker();

  static const int maxFileSizeBytes = 1024 * 1024; // 1 МБ

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
    final tempFile = File('${tempDir.path}/avatar_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(bytes);

    return tempFile;
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_compressedImage == null) return null;

    try {
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('profile').upload(fileName, _compressedImage!);
      return supabase.storage.from('profile').getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки фото')),
        );
      }
      return null;
    }
  }

  Future<void> _registerAndNavigate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароли не совпадают')),
      );
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
        'about': _selectedRole == UserRole.specialist ? _aboutController.text.trim() : null,
        'specialty': _selectedRole == UserRole.specialist ? _specialtyController.text.trim() : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Регистрация успешна!')),
        );

        if (role == 'specialist') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => SpecialistHome(displayName: _displayNameController.text.trim())),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => UserHome(displayName: _displayNameController.text.trim())),
          );
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ошибка регистрации')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndCompressImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    backgroundImage: _compressedImage != null
                        ? FileImage(_compressedImage!)
                        : (_originalImage != null ? FileImage(_originalImage!) : null),
                    child: (_compressedImage == null && _originalImage == null)
                        ? Icon(Icons.add_a_photo, size: 40, color: colorScheme.primary)
                        : null,
                  ),
                  if (_isLoading && _compressedImage == null)
                    const CircularProgressIndicator(strokeWidth: 3),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _compressedImage != null
                  ? 'Фото готово (${(_compressedImage!.lengthSync() ~/ 1024).toStringAsFixed(0)} КБ)'
                  : _isLoading
                      ? 'Сжатие фото...'
                      : 'Нажмите, чтобы выбрать фото',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(value: UserRole.user, label: Text('Пользователь')),
                ButtonSegment(value: UserRole.specialist, label: Text('Специалист')),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (set) => setState(() => _selectedRole = set.first),
            ),

            const SizedBox(height: 24),

            TextFormField(
              controller: _displayNameController,
              validator: (v) => v!.trim().isEmpty ? 'Введите имя' : null,
              decoration: const InputDecoration(labelText: 'Отображаемое имя *', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.trim().isEmpty || !v.contains('@') ? 'Неверный email' : null,
              decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              validator: (v) => v!.length < 6 ? 'Минимум 6 символов' : null,
              decoration: InputDecoration(
                labelText: 'Пароль *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Подтвердите пароль *',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),

            if (_selectedRole == UserRole.specialist) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _aboutController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'О себе', prefixIcon: Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Специальность',
                  hintText: 'Например: Сантехник, Электрик',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
            ],

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _registerAndNavigate,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}