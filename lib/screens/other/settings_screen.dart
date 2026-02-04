import 'package:flutter/material.dart';
import 'package:profi/main.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/other/settings_screen/settings_section_header.dart';
import '../../widgets/other/settings_screen/theme_selector_bottom_sheet.dart';
import '../../screens/other/service_chat_screen.dart';

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

  void _openSupportChat(BuildContext context) {
    final supportSpecialist = {
      'id': 'f6937ce1-f3cb-4484-83f6-8bdd2fe84110',
      'display_name': 'Служба поддержки',
      'photo_url': null,
      'specialty': 'Помощь 24/7',
      'about': 'Мы ответим в течение 5–15 минут',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceChatScreen(
          specialist: supportSpecialist,
          service: null,
        ),
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PolicyScreen(title: 'Политика конфиденциальности'),
      ),
    );
  }

  void _openTermsOfUse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PolicyScreen(title: 'Условия использования'),
      ),
    );
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
        title: Text('Настройки',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),),
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
            leading: Icon(Icons.delete_forever_rounded, color: colorScheme.error),
            title: const Text('Удалить аккаунт'),
            subtitle: const Text('Удаляет все данные без возможности восстановления'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => _deleteAccount(context),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          const SettingsSectionHeader(title: 'Поддержка и информация'),
          ListTile(
            leading: Icon(Icons.support_agent_rounded, color: colorScheme.primary),
            title: const Text('Служба поддержки'),
            subtitle: const Text('Чат с поддержкой'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => _openSupportChat(context),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_rounded, color: colorScheme.primary),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => _openPrivacyPolicy(context),
          ),
          ListTile(
            leading: Icon(Icons.description_rounded, color: colorScheme.primary),
            title: const Text('Условия использования'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => _openTermsOfUse(context),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(
                  'Версия 1.0.0',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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

// Новый экран для отображения текста политики / условий
class PolicyScreen extends StatelessWidget {
  final String title;

  const PolicyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPrivacy = title == 'Политика конфиденциальности';

    return Scaffold(
      appBar: AppBar(
        title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дипломная работа',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Студент колледжа МГКЦТ\n'
              'Картун Ярослав Сергеевич\n'
              'Группа: 75МС\n',
              style: theme.textTheme.titleMedium?.copyWith(
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              isPrivacy ? 'Политика конфиденциальности' : 'Условия использования',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Text(
              isPrivacy
                  ? '1. Общие положения\n\n'
                      'Настоящая Политика конфиденциальности регулирует порядок обработки и защиты персональных данных пользователей мобильного приложения ProWirkSearch, разработанного в рамках дипломной работы студента Картуна Ярослава Сергеевича.\n\n'
                      'Приложение создано исключительно в учебных целях и не является коммерческим продуктом. Разработчик не несёт ответственности за возможные последствия использования приложения после завершения дипломной работы.\n\n'
                  : '1. Общие положения\n\n'
                      'Настоящие Условия использования регулируют порядок использования мобильного приложения ProWirkSearch, разработанного в рамках дипломной работы студента Картуна Ярослава Сергеевича.\n\n'
                      'Приложение предназначено исключительно для демонстрации функциональности в рамках дипломной работы и не предназначено для коммерческого использования.\n\n',

              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),

            Text(
              isPrivacy
                  ? '2. Какие данные собираются\n\n'
                      '• ФИО (display_name)\n'
                      '• Электронная почта\n'
                      '• Фотография профиля (при загрузке)\n'
                      '• Данные заказов, чатов, отзывов\n'
                      '• IP-адрес и технические данные устройства\n\n'
                  : '2. Правила использования\n\n'
                      'Пользователь обязуется:\n'
                      '• Не использовать Приложение для оскорблений, угроз, спама\n'
                      '• Не размещать противоправный контент\n'
                      '• Не пытаться взламывать или дестабилизировать работу Приложения\n\n',

              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),

            Text(
              isPrivacy
                  ? '3. Как используются данные\n\n'
                      'Данные используются исключительно для работы функционала Приложения (профили, чаты, заказы, отзывы).\n'
                  : '3. Ответственность сторон\n\n'
                      'Приложение предоставляется «как есть». Разработчик не несёт ответственности за:\n'
                      '• Потерю данных пользователя\n'
                      '• Убытки, возникшие в результате использования Приложения\n'
                      '• Действия других пользователей\n\n',

              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),

            Text(
              isPrivacy
                  ? '4. Хранение и защита данных\n\n'
                      'Данные хранятся в облачной базе Supabase (защищённое хранилище).\n'
                      'Приложение использует HTTPS, токены авторизации и другие стандартные средства защиты.\n\n'
                  : '4. Интеллектуальная собственность\n\n'
                      'Все права на дизайн, код, тексты и структуру Приложения принадлежат МГКЦТ\n',

              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),

            const SizedBox(height: 24),

            Text(
              'Дата составления документа: февраль 2026 г.\n'
              'Разработчик: Картун Ярослав Сергеевич\n'
              'Колледж: МГКЦТ',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}