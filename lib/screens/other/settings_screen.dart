import 'package:flutter/material.dart';
import 'package:profi/main.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/other/settings_screen/settings_section_header.dart';
import '../../widgets/other/settings_screen/theme_selector_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить аккаунт навсегда?'),
        content: const Text(
          'Все ваши данные будут безвозвратно удалены:\n'
          '• профиль\n'
          '• заказы\n'
          '• отзывы\n'
          '• сообщения\n'
          '• сохранённые услуги\n'
          '• документы и услуги (если вы специалист)\n\n'
          'Действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Удалить',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Удаление аккаунта...'),
          duration: Duration(seconds: 10),
        ),
      );

      await supabase.from('orders').delete().eq('user_id', user.id);
      await supabase.from('reviews').delete().eq('user_id', user.id);
      await supabase.from('saved_services').delete().eq('user_id', user.id);
      await supabase
          .from('chat_messages')
          .delete()
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');

      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      if (profile['role'] == 'specialist') {
        final services = await supabase
            .from('services')
            .select('id')
            .eq('specialist_id', user.id);
        final serviceIds = services.map((s) => s['id']).toList();

        if (serviceIds.isNotEmpty) {
          await supabase
              .from('service_photos')
              .delete()
              .inFilter('service_id', serviceIds);
        }

        await supabase.from('services').delete().eq('specialist_id', user.id);
        await supabase.from('documents').delete().eq('specialist_id', user.id);
        await supabase.from('orders').delete().eq('specialist_id', user.id);
        await supabase.from('reviews').delete().eq('specialist_id', user.id);
      }

      await supabase.from('profiles').delete().eq('id', user.id);

      await supabase.auth.admin.deleteUser(user.id);

      await supabase.auth.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аккаунт и все данные удалены')),
        );
      }
    } catch (e, stack) {
      debugPrint('Ошибка удаления: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.themeMode;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Внешний вид'),
          ListTile(
            leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
            title: const Text('Тема приложения'),
            subtitle: Text(
              currentMode == ThemeMode.light
                  ? 'Светлая'
                  : currentMode == ThemeMode.dark
                  ? 'Тёмная'
                  : 'Системная',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                builder: (context) => const ThemeSelectorBottomSheet(),
              );
            },
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          const SettingsSectionHeader(title: 'Аккаунт и безопасность'),
          ListTile(
            leading: Icon(
              Icons.delete_forever_rounded,
              color: colorScheme.error,
            ),
            title: const Text('Удалить аккаунт'),
            subtitle: const Text(
              'Удаляет все данные без возможности восстановления',
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => _deleteAccount(context),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          const SettingsSectionHeader(title: 'Поддержка и информация'),
          ListTile(
            leading: Icon(
              Icons.support_agent_rounded,
              color: colorScheme.primary,
            ),
            title: const Text('Служба поддержки'),
            subtitle: const Text('Чат, email или звонок'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Связь со службой поддержки (в разработке)',
                  ),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.privacy_tip_rounded,
              color: colorScheme.primary,
            ),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Открытие политики (в разработке)'),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.description_rounded,
              color: colorScheme.primary,
            ),
            title: const Text('Условия использования'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: const Text('Открытие условий (в разработке)'),
                ),
              );
            },
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(
                  'Версия 1.0.0',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ProWirkSearch',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
