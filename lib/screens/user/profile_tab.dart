// lib/widgets/user/profile_tab/profile_tab.dart
import 'package:flutter/material.dart';
import 'package:profi/screens/auth/auth_screen.dart';
import 'package:profi/widgets/user/profile_tab/edit_profile_form.dart';
import 'package:profi/widgets/user/profile_tab/profile_view.dart';
import '../../../services/supabase_service.dart';

class UserProfileTab extends StatefulWidget {
  const UserProfileTab({super.key});

  @override
  State<UserProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<UserProfileTab> {
  bool _isLoading = true;
  bool _isEditing = false;

  String? _displayName;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'Не авторизован';

      final response = await supabase
          .from('profiles')
          .select('display_name, photo_url')
          .eq('id', userId)
          .single();

      setState(() {
        _displayName = response['display_name'] as String;
        _photoUrl = response['photo_url'] as String?;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile(String name, String? photoUrl) async {
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'display_name': name,
        'photo_url': photoUrl,
      }).eq('id', userId);

      setState(() {
        _displayName = name;
        _photoUrl = photoUrl;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _isEditing
        ? EditProfileForm(
            initialName: _displayName ?? '',
            initialPhotoUrl: _photoUrl,
            onSave: _saveProfile,
            onCancel: _cancelEditing,
          )
        : ProfileView(
            displayName: _displayName,
            photoUrl: _photoUrl,
            onEdit: _startEditing,
            onLogout: _logout,
          );
  }
}