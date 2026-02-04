import 'package:flutter/material.dart';
import 'package:profi/services/supabase_service.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await supabase
          .from('profiles')
          .select('id, role, display_name, about, specialty, photo_url, created_at')
          .order('created_at', ascending: false)
          .limit(150);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки пользователей: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showUserEditDialog(Map<String, dynamic> user) async {
    final colorScheme = Theme.of(context).colorScheme;

    final displayNameCtrl = TextEditingController(text: user['display_name'] ?? '');
    final aboutCtrl = TextEditingController(text: user['about'] ?? '');
    final specialtyCtrl = TextEditingController(text: user['specialty'] ?? '');
    final photoUrlCtrl = TextEditingController(text: user['photo_url'] ?? '');
    String? selectedRole = user['role'];

    final roles = ['user', 'specialist', 'admin'];

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: colorScheme.surfaceContainerHigh,
              title: Text(
                'Профиль: ${user['display_name'] ?? 'Без имени'}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${user['id']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: displayNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Имя / Ник',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: aboutCtrl,
                      decoration: InputDecoration(
                        labelText: 'О себе',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 4,
                      minLines: 3,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: specialtyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Специальность',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: photoUrlCtrl,
                      decoration: InputDecoration(
                        labelText: 'URL фотографии',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Роль',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: roles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedRole = v),
                    ),
                    const SizedBox(height: 32),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: Icon(Icons.delete_forever, color: colorScheme.error),
                        label: Text(
                          'Удалить профиль',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: dialogContext,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              title: const Text('Удалить пользователя?'),
                              content: const Text(
                                'Действие нельзя отменить.\nСвязанные данные (заказы, отзывы, услуги и т.д.) также будут удалены.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Удалить', style: TextStyle(color: colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;

    // Удаление профиля
    if (shouldDelete == true) {
      try {
        await supabase.from('profiles').delete().eq('id', user['id']);
        await _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении профиля: $e'),
              backgroundColor: colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
      return;
    }

    // Сохранение изменений
    try {
      final updates = {
        'display_name': displayNameCtrl.text.trim().isNotEmpty ? displayNameCtrl.text.trim() : null,
        'about': aboutCtrl.text.trim().isNotEmpty ? aboutCtrl.text.trim() : null,
        'specialty': specialtyCtrl.text.trim().isNotEmpty ? specialtyCtrl.text.trim() : null,
        'photo_url': photoUrlCtrl.text.trim().isNotEmpty ? photoUrlCtrl.text.trim() : null,
        'role': selectedRole,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await supabase.from('profiles').update(updates).eq('id', user['id']);
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при сохранении профиля: $e'),
            backgroundColor: colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
          'Пользователей пока нет',
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerLowest,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final role = user['role'] as String? ?? '—';
          final name = user['display_name'] as String? ?? 'Без имени';
          final date = user['created_at']?.toString().substring(0, 10) ?? '';

          final bool isSpecialist = role == 'specialist';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surfaceContainerLow,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showUserEditDialog(user),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundImage: user['photo_url'] != null ? NetworkImage(user['photo_url']) : null,
                    child: user['photo_url'] == null
                        ? Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  title: Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user['id'].toString().substring(0, 8)}…',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        'Роль: $role • $date',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  trailing: isSpecialist
                      ? Chip(
                          label: Text(
                            'Мастер',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: colorScheme.primaryContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}