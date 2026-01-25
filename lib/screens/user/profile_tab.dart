// lib/screens/user/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/models/profile_stats.dart';
import 'package:profi/services/profile_service.dart';
import 'package:profi/widgets/user/profile_tab/my_orders_screen.dart';
import 'package:profi/widgets/user/profile_tab/my_reviews_screen.dart';
import 'package:profi/widgets/user/profile_tab/profile_avatar.dart';
import 'package:profi/widgets/user/profile_tab/profile_info.dart';
import 'package:profi/widgets/user/profile_tab/profile_stats_row.dart';
import 'package:profi/widgets/user/profile_tab/edit_profile_form.dart';
import 'package:profi/screens/other/settings_screen.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import 'package:profi/services/supabase_service.dart';

class UserProfileTab extends StatefulWidget {
  const UserProfileTab({super.key});

  @override
  State<UserProfileTab> createState() => _UserProfileTabState();
}

class _UserProfileTabState extends State<UserProfileTab>
    with SingleTickerProviderStateMixin {
  final _profileService = ProfileService();

  bool _isLoading = true;
  bool _isEditing = false;

  String? _displayName;
  String? _photoUrl;
  String? _role;
  String? _specialty;
  ProfileStats _stats = ProfileStats();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        title: Text(
          'Информация профиля',
          style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings_outlined),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch, // ← важно для растяжки
              children: [
                // Блок аватар + информация — теперь растянут на всю ширину как статистика
                Card(
                  elevation: 16, // заметная, но не тяжёлая тень
                  //shadowColor: Colors.black.withOpacity(0.30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  color: colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ProfileAvatar(
                          photoUrl: _photoUrl,
                          displayName: _displayName,
                        ),
                        const SizedBox(height: 6),
                        ProfileInfo(
                          displayName: _displayName,
                          role: _role,
                          specialty: _specialty,
                          email: supabase.auth.currentUser?.email,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Статистика — тот же стиль, elevation, радиус, цвет
                Card(
                  elevation: 16,
                  //shadowColor: Colors.black.withOpacity(0.30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  color:
                      colorScheme.surfaceContainerLow, // одинаковый с аватаром
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: ProfileStatsRow(stats: _stats, role: _role),
                  ),
                ),

                const SizedBox(height: 12),

                // Кнопки действий — с небольшой тенью
                _buildActionButton(
                  context,
                  icon: Icons.receipt_long_rounded,
                  label: 'Мои заказы',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                  ),
                  isPrimary: false,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  icon: Icons.rate_review_rounded,
                  label: 'Мои отзывы',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                  ),
                  isPrimary: false,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  icon: Icons.edit_rounded,
                  label: 'Редактировать профиль',
                  onPressed: _startEditing,
                  isPrimary: true,
                ),

                const SizedBox(height: 12),

                // Выход — danger action с тенью
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                  label: Text(
                    'Выйти из аккаунта',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    elevation: 1, // небольшая тень под кнопкой
                    shadowColor: colorScheme.error.withOpacity(0.25),
                    minimumSize: const Size.fromHeight(56),
                    side: BorderSide(color: colorScheme.errorContainer),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    Theme.of(context);

    final baseStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevation: const WidgetStatePropertyAll(2), // тень под всеми кнопками
      shadowColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.18)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
    );

    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: baseStyle.merge(FilledButton.styleFrom()),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: baseStyle.merge(OutlinedButton.styleFrom()),
      );
    }
  }
}
