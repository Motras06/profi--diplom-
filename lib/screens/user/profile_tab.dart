// lib/screens/user/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/models/profile_stats.dart';
import 'package:profi/services/profile_service.dart';
import 'package:profi/widgets/user/profile_tab/my_orders_screen.dart';
import 'package:profi/widgets/user/profile_tab/my_reviews_screen.dart';
import 'package:profi/widgets/user/profile_tab/profile_avatar.dart';
import 'package:profi/widgets/user/profile_tab/profile_info.dart';
import 'package:profi/widgets/user/profile_tab/profile_stats_row.dart';
import 'package:profi/widgets/user/profile_tab/profile_action_button.dart';
import 'package:profi/widgets/user/profile_tab/edit_profile_form.dart';
import 'package:profi/screens/other/settings_screen.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import 'package:profi/services/supabase_service.dart';

class UserProfileTab extends StatefulWidget {
  const UserProfileTab({super.key});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab> {
  final _profileService = ProfileService();

  bool _isLoading = true;
  bool _isEditing = false;

  String? _displayName;
  String? _photoUrl;
  String? _role;
  String? _specialty;
  ProfileStats _stats = ProfileStats();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Не авторизован');

      final profile = await _profileService.fetchProfile(user.id);
      final stats = await _profileService.fetchStats(user.id, profile['role']);

      if (mounted) {
        setState(() {
          _displayName = profile['display_name'] as String?;
          _photoUrl = profile['photo_url'] as String?;
          _role = profile['role'] as String?;
          _specialty = profile['specialty'] as String?;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile(String name, String? photoUrl) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _profileService.updateProfile(userId, name, photoUrl);

      if (mounted) {
        setState(() {
          _displayName = name.trim();
          _photoUrl = photoUrl;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль сохранён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  void _startEditing() => setState(() => _isEditing = true);
  void _cancelEditing() => setState(() => _isEditing = false);

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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfileAvatar(
              photoUrl: _photoUrl,
              displayName: _displayName,
            ),
            ProfileInfo(
              displayName: _displayName,
              role: _role,
              specialty: _specialty,
              email: supabase.auth.currentUser?.email,
            ),
            ProfileStatsRow(stats: _stats, role: _role),
            const SizedBox(height: 48),
            ProfileActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'Мои заказы',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ProfileActionButton(
              icon: Icons.rate_review_outlined,
              label: 'Мои отзывы',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ProfileActionButton(
              icon: Icons.edit,
              label: 'Редактировать профиль',
              onPressed: _startEditing,
              isFilled: true,
            ),
            const SizedBox(height: 32),
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
          ],
        ),
      ),
    );
  }
}