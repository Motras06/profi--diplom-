// lib/main.dart
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:profi/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/user/user_home.dart';
import 'screens/specialist/specialist_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
        child: const MainApp(),
      ),
    ),
  );
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // Определяем стартовый экран в зависимости от роли пользователя
  Future<Widget> _getStartingScreen() async {
    final currentUser = supabase.auth.currentUser;

    // Если пользователь не авторизован — экран входа
    if (currentUser == null) {
      return const AuthScreen();
    }

    try {
      final response = await supabase
          .from('profiles')
          .select('role, display_name')
          .eq('id', currentUser.id)
          .single();

      final String role = response['role'];
      final String displayName = response['display_name'] ?? 'Пользователь';

      if (role == 'specialist') {
        return SpecialistHome(displayName: displayName);
      } else {
        return UserHome(displayName: displayName);
      }
    } catch (e) {
      // Если профиль не найден или ошибка — возвращаем на авторизацию
      return const AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ProWirkSearch',
      debugShowCheckedModeBanner: false,

      // ← Вот ключевые изменения
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // DevicePreview настройки
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      home: FutureBuilder<Widget>(
        future: _getStartingScreen(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return snapshot.data!;
          if (snapshot.hasError) return const AuthScreen();

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

/*
================================================================================
ИНСТРУКЦИЯ ПО ПОВТОРНОМУ ПОДКЛЮЧЕНИЮ DEVICE PREVIEW (для разработки)
================================================================================

Если тебе нужно снова включить DevicePreview (для тестирования на разных устройствах):

1. Убедись, что в pubspec.yaml есть зависимость:
   dependencies:
     device_preview: ^1.0.0

2. Замени содержимое main() и runApp на это:

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     await dotenv.load(fileName: ".env");

     await Supabase.initialize(
       url: dotenv.env['SUPABASE_URL']!,
       anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
     );

     runApp(
       DevicePreview(
         enabled: !kReleaseMode, // Автоматически выключается в релизе
         builder: (context) => const MainApp(),
       ),
     );
   }

3. В MaterialApp добавь:
   useInheritedMediaQuery: true,
   locale: DevicePreview.locale(context),
   builder: DevicePreview.appBuilder,

Готово! Теперь можно тестировать на разных экранах, шрифтах и локалях.

Удаляй эти строки при финальной сборке/показе.
================================================================================
*/
