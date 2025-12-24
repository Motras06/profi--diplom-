// lib/screens/auth/login_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/specialist/specialist_home.dart';
import 'package:profi/screens/user/user_home.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class LoginTab extends StatefulWidget {
  const LoginTab({super.key});

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // Состояние видимости пароля

  Future<void> _loginAndNavigate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        await _navigateToHome();
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToHome() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _goToUserHome('Гость');
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role, display_name')
          .eq('id', user.id)
          .single();

      final role = profile['role'] as String;
      final name = profile['display_name'] as String;

      if (role == 'specialist') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SpecialistHome(displayName: name)),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => UserHome(displayName: name)),
        );
      }
    } catch (e) {
      _goToUserHome('Пользователь');
    }
  }

  void _goToUserHome(String name) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UserHome(displayName: name)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.trim().isEmpty ? 'Введите email' : null,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, // Скрытие/показ пароля
              validator: (v) => v!.isEmpty ? 'Введите пароль' : null,
              decoration: InputDecoration(
                labelText: 'Пароль',
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
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _loginAndNavigate,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}