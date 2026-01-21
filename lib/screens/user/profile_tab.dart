// lib/widgets/user/profile_tab/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/other/my_orders_screen.dart';
import 'package:profi/screens/other/my_reviews_screen.dart';
import 'package:profi/screens/other/settings_screen.dart';
import 'package:profi/widgets/user/profile_tab/edit_profile_form.dart';
import '../../../services/supabase_service.dart';
import '../../../screens/auth/auth_screen.dart';

class UserProfileTab extends StatefulWidget {
  const UserProfileTab({super.key});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  bool _isLoading = true;
  bool _isEditing = false;

  String? _displayName;
  String? _photoUrl;
  String? _role; // 'client' | 'specialist' | null
  String? _specialty;

  // Статистика
  int _ordersCount = 0;
  int _reviewsCount = 0;
  int _savedServicesCount = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileAndStats();
  }

  Future<void> _loadProfileAndStats() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Не авторизован');

      // 1. Профиль
      final profileRes = await supabase
          .from('profiles')
          .select('display_name, photo_url, role, specialty')
          .eq('id', user.id)
          .single();

      setState(() {
        _displayName = profileRes['display_name'] as String?;
        _photoUrl = profileRes['photo_url'] as String?;
        _role = profileRes['role'] as String?;
        _specialty = profileRes['specialty'] as String?;
      });

      // 2. Статистика
      final ordersRes = await supabase
          .from('orders')
          .select('count')
          .eq('user_id', user.id);
      _ordersCount = (ordersRes.firstOrNull?['count'] as int?) ?? 0;

      final savedRes = await supabase
          .from('saved_services')
          .select('count')
          .eq('user_id', user.id);
      _savedServicesCount = (savedRes.firstOrNull?['count'] as int?) ?? 0;

      if (_role == 'specialist') {
        final reviewsRes = await supabase
            .from('reviews')
            .select('count, avg(rating)')
            .eq('specialist_id', user.id)
            .single();

        _reviewsCount = (reviewsRes['count'] as int?) ?? 0;
        _averageRating = (reviewsRes['avg'] as num?)?.toDouble() ?? 0.0;
      } else {
        final myReviewsRes = await supabase
            .from('reviews')
            .select('count')
            .eq('user_id', user.id);
        _reviewsCount = (myReviewsRes.firstOrNull?['count'] as int?) ?? 0;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditing() => setState(() => _isEditing = true);
  void _cancelEditing() => setState(() => _isEditing = false);

  Future<void> _saveProfile(String name, String? photoUrl) async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'display_name': name.trim(),
        'photo_url': photoUrl,
      }).eq('id', userId);

      setState(() {
        _displayName = name.trim();
        _photoUrl = photoUrl;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль сохранён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  // Переходы
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _openMyOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
    );
  }

  void _openMyReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyReviewsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isEditing) {
      return EditProfileForm(
        initialName: _displayName ?? '',
        initialPhotoUrl: _photoUrl,
        onSave: _saveProfile,
        onCancel: _cancelEditing,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: _openSettings,  // ← теперь в AppBar — надёжно работает
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Аватар + имя + роль
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
              child: _photoUrl == null
                  ? Text(
                      (_displayName?.substring(0, 1).toUpperCase()) ?? '?',
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            Text(
              _displayName ?? 'Имя не указано',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),

            if (_role != null) ...[
              const SizedBox(height: 6),
              Chip(
                label: Text(
                  _role == 'specialist' ? (_specialty ?? 'Специалист') : 'Клиент',
                ),
                backgroundColor: _role == 'specialist' ? Colors.blue.shade100 : Colors.green.shade100,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              supabase.auth.currentUser?.email ?? '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),

            const SizedBox(height: 40),

            // Статистика
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(icon: Icons.work_outline, value: '$_ordersCount', label: 'Заказов'),
                _StatCard(
                  icon: Icons.star_outline,
                  value: _role == 'specialist' ? _averageRating.toStringAsFixed(1) : '$_reviewsCount',
                  label: _role == 'specialist' ? 'Рейтинг' : 'Отзывов',
                ),
                _StatCard(icon: Icons.bookmark_border, value: '$_savedServicesCount', label: 'Сохранено'),
              ],
            ),

            const SizedBox(height: 48),

            // Основные действия
            _ActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'Мои заказы',
              onPressed: _openMyOrders,
            ),
            const SizedBox(height: 16),

            _ActionButton(
              icon: Icons.rate_review_outlined,
              label: 'Мои отзывы',
              onPressed: _openMyReviews,
            ),
            const SizedBox(height: 16),

            _ActionButton(
              icon: Icons.edit,
              label: 'Редактировать профиль',
              onPressed: _startEditing,
              isFilled: true,
            ),
            const SizedBox(height: 24),

            // Выход
            OutlinedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, color: Colors.red.shade700),
              label: Text(
                'Выйти из аккаунта',
                style: TextStyle(color: Colors.red.shade700),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Вспомогательные виджеты (без изменений)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isFilled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFilled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}