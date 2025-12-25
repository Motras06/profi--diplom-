// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/user/user_home.dart';
import 'screens/specialist/specialist_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Загрузка .env файла
  await dotenv.load(fileName: ".env");

  // Инициализация Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MainApp());
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
    return MaterialApp(
      title: 'Найди Мастера',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<Widget>(
        future: _getStartingScreen(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return snapshot.data!;
          } else if (snapshot.hasError) {
            return const AuthScreen();
          }

          // Экран загрузки при определении роли
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF009999)),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Загрузка приложения...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
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