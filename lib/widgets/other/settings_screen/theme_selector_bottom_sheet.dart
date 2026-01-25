// lib/widgets/other/settings_screen/theme_selector_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

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
                Navigator.pop(context);
              }
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
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.pop(context);
              }
            },
            title: const Text('Светлая'),
            secondary: const Icon(Icons.light_mode_rounded),
            activeColor: colorScheme.primary,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
                Navigator.pop(context);
              }
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