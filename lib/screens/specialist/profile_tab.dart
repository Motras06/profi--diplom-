import 'package:flutter/material.dart';
import 'package:prowirksearch/screens/auth/auth_screen.dart';
import 'package:prowirksearch/widgets/specialist/profile_tab/documents.dart';
import 'package:prowirksearch/widgets/specialist/profile_tab/edit_profile_form.dart';
import 'package:prowirksearch/screens/other/settings_screen.dart';
import '../../../services/supabase_service.dart';

class ProfileTab extends StatefulWidget {
  final String displayName;

  const ProfileTab({super.key, required this.displayName});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isEditing = false;

  String? _displayName;
  String? _about;
  String? _specialty;
  String? _photoUrl;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _loadProfile();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Не авторизован';

      final response = await supabase
          .from('profiles')
          .select('display_name, about, specialty, photo_url')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _displayName = response['display_name'] as String?;
          _about = response['about'] as String?;
          _specialty = response['specialty'] as String?;
          _photoUrl = response['photo_url'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки профиля: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile(
    String name,
    String? about,
    String? specialty,
    String? photoUrl,
  ) async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('profiles')
          .update({
            'display_name': name.trim(),
            'about': about?.trim(),
            'specialty': specialty?.trim(),
            'photo_url': photoUrl,
          })
          .eq('id', userId);

      if (mounted) {
        setState(() {
          _displayName = name.trim();
          _about = about?.trim();
          _specialty = specialty?.trim();
          _photoUrl = photoUrl;
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Профиль сохранён!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
        setState(() => _isLoading = false);
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
        initialAbout: _about,
        initialSpecialty: _specialty,
        initialPhotoUrl: _photoUrl,
        onSave: _saveProfile,
        onCancel: _cancelEditing,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Профиль',
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
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 16,
                    shadowColor: colorScheme.shadow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    color: colorScheme.surfaceContainerLow,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 64,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundImage: _photoUrl != null
                                ? NetworkImage(_photoUrl!)
                                : null,
                            child: _photoUrl == null
                                ? Text(
                                    _displayName?.isNotEmpty == true
                                        ? _displayName![0].toUpperCase()
                                        : 'М',
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _displayName ?? 'Мастер',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_specialty != null && _specialty!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _specialty!,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text('Редактировать профиль'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(56),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_about != null && _about!.isNotEmpty)
                    Card(
                      elevation: 16,
                      shadowColor: colorScheme.shadow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      color: colorScheme.surfaceContainerLow,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'О себе',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _about!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.folder_outlined,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      title: const Text(
                        'Мои документы',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Сертификаты, дипломы, лицензии'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SpecialistDocuments(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: Icon(Icons.logout_rounded, color: colorScheme.error),
                    label: Text(
                      'Выйти из аккаунта',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      elevation: 2,
                      shadowColor: colorScheme.error.withOpacity(0.25),
                      side: BorderSide(color: colorScheme.errorContainer),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
