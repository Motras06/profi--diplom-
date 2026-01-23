// lib/screens/other/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart'; // создадим этот файл ниже

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          // Секция "Внешний вид"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Внешний вид',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
            title: const Text('Тема приложения'),
            subtitle: Text(
              currentMode == ThemeMode.light
                  ? 'Светлая'
                  : currentMode == ThemeMode.dark
                      ? 'Тёмная'
                      : 'Системная',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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

          // Секция "Аккаунт и безопасность"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Аккаунт и безопасность',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: colorScheme.error),
            title: const Text('Удалить аккаунт'),
            subtitle: Text(
              'Удаляет все данные без возможности восстановления',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Функция в разработке'),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          // Секция "Поддержка и информация"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Поддержка и информация',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.support_agent_rounded, color: colorScheme.primary),
            title: const Text('Служба поддержки'),
            subtitle: const Text('Чат, email или звонок'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Связь со службой поддержки (в разработке)'),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.privacy_tip_rounded, color: colorScheme.primary),
            title: const Text('Политика конфиденциальности'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: const Text('Открытие политики (в разработке)')),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.description_rounded, color: colorScheme.primary),
            title: const Text('Условия использования'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: const Text('Открытие условий (в разработке)')),
              );
            },
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          // Футер
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
                  'Найди Мастера © 2025–2026',
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

// Bottom Sheet для выбора темы
class ThemeSelectorBottomSheet extends StatelessWidget {
  const ThemeSelectorBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentMode = themeProvider.themeMode;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Выберите тему',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
            ),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
              Navigator.pop(context);
            },
            title: const Text('Системная'),
            subtitle: const Text('Следует настройкам устройства'),
            secondary: const Icon(Icons.settings_suggest_rounded),
            activeColor: colorScheme.primary,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) themeProvider.setThemeMode(value);
              Navigator.pop(context);
            },
            title: const Text('Светлая'),
            secondary: const Icon(Icons.light_mode_rounded),
            activeColor: colorScheme.primary,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) themeProvider.setThemeMode(value);
              Navigator.pop(context);
            },
            title: const Text('Тёмная'),
            secondary: const Icon(Icons.dark_mode_rounded),
            activeColor: colorScheme.primary,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}